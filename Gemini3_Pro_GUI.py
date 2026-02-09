#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import tkinter as tk
from tkinter import ttk, scrolledtext, filedialog, messagebox
import requests
import json
import base64
import os
import threading
from PIL import Image, ImageTk
from io import BytesIO
import datetime

USE_TKDND = False
TkinterDnD = None
DND_FILES = None


class DropZone(tk.Frame):
    def __init__(self, parent, title, index, callback, **kwargs):
        super().__init__(parent, bg="#e0e0e0", width=90, height=110, **kwargs)
        self.index = index
        self.callback = callback
        self.path = None
        self.pack_propagate(False)
        
        tk.Label(self, text=title, bg="#e0e0e0", font=("微软雅黑", 9)).pack(pady=2)
        
        self.canvas = tk.Canvas(self, width=70, height=70, bg="#f5f5f5", highlightthickness=1)
        self.canvas.pack()
        self.canvas.create_text(35, 35, text="+", font=("微软雅黑", 24), fill="#999")
        
        tk.Button(self, text="清除", command=self.clear, font=("微软雅黑", 8), 
                 bg="#e0e0e0", relief=tk.FLAT).pack(fill=tk.X, padx=5, pady=2)
        
        self.canvas.bind("<Button-1>", self.on_click)
        
    def enable_drop(self):
        global USE_TKDND, DND_FILES
        if USE_TKDND:
            try:
                self.canvas.drop_target_register(DND_FILES)
                self.canvas.dnd_bind('<<Drop>>', self.on_drop)
            except:
                pass
                
    def on_drop(self, event):
        path = event.data.strip('{}')
        if os.path.exists(path) and path.lower().endswith(('.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp')):
            self.load(path)
            
    def on_click(self, e):
        path = filedialog.askopenfilename(filetypes=[("图片", "*.png *.jpg *.jpeg *.gif *.bmp *.webp")])
        if path:
            self.load(path)
            
    def load(self, path):
        try:
            img = Image.open(path)
            img.thumbnail((66, 66))
            self.photo = ImageTk.PhotoImage(img)
            self.canvas.delete("all")
            self.canvas.create_image(35, 35, image=self.photo)
            self.path = path
            self.callback(self.index, path)
        except:
            pass
            
    def clear(self):
        self.path = None
        self.canvas.delete("all")
        self.canvas.create_text(35, 35, text="+", font=("微软雅黑", 24), fill="#999")
        self.callback(self.index, None)
        
    def get_path(self):
        return self.path


class ScrollableFrame(tk.Frame):
    """可滚动的Frame"""
    def __init__(self, parent, **kwargs):
        super().__init__(parent, **kwargs)
        
        self.canvas = tk.Canvas(self, highlightthickness=0)
        self.scrollbar = ttk.Scrollbar(self, orient="vertical", command=self.canvas.yview)
        self.scrollable_frame = tk.Frame(self.canvas)
        
        self.scrollable_frame.bind(
            "<Configure>",
            lambda e: self.canvas.configure(scrollregion=self.canvas.bbox("all"))
        )
        
        self.canvas.create_window((0, 0), window=self.scrollable_frame, anchor="nw")
        self.canvas.configure(yscrollcommand=self.scrollbar.set)
        
        self.canvas.pack(side="left", fill="both", expand=True)
        self.scrollbar.pack(side="right", fill="y")
        
        # 鼠标滚轮
        self.canvas.bind_all("<MouseWheel>", self._on_mousewheel)
        
    def _on_mousewheel(self, event):
        self.canvas.yview_scroll(int(-1*(event.delta/120)), "units")


class Gemini3ProGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Gemini 3 Pro 图像生成器")
        self.root.geometry("1200x800")
        self.root.minsize(1100, 700)
        
        self.drop_zones = []
        self.generated_images = []
        self.default_api = "https://aigc002.com/v1beta/models/gemini-3-pro-image-preview:generateContent"
        
        self.build_ui()
        self.load_config()
        
    def build_ui(self):
        # 主分割面板
        paned = tk.PanedWindow(self.root, orient=tk.HORIZONTAL, sashrelief=tk.RAISED, sashwidth=5)
        paned.pack(fill=tk.BOTH, expand=True, padx=3, pady=3)
        
        # ===== 左侧：可滚动面板 =====
        left_container = tk.Frame(paned, width=380)
        paned.add(left_container)
        
        left_scroll = ScrollableFrame(left_container)
        left_scroll.pack(fill=tk.BOTH, expand=True)
        left = left_scroll.scrollable_frame
        
        # 1. API设置
        api_box = tk.LabelFrame(left, text="API设置", font=("微软雅黑", 10, "bold"), padx=5, pady=5)
        api_box.pack(fill=tk.X, pady=3)
        
        tk.Label(api_box, text="API地址:").pack(anchor=tk.W)
        self.api_url = tk.StringVar(value=self.default_api)
        tk.Entry(api_box, textvariable=self.api_url).pack(fill=tk.X, pady=2)
        
        tk.Label(api_box, text="API Key:").pack(anchor=tk.W)
        self.api_key = tk.StringVar()
        self.api_key_entry = tk.Entry(api_box, textvariable=self.api_key, show="*")
        self.api_key_entry.pack(fill=tk.X, pady=2)
        
        api_btn = tk.Frame(api_box)
        api_btn.pack(fill=tk.X, pady=5)
        tk.Button(api_btn, text="保存配置", command=self.save_config).pack(side=tk.LEFT, padx=2)
        tk.Button(api_btn, text="加载配置", command=self.load_config).pack(side=tk.LEFT, padx=2)
        tk.Checkbutton(api_btn, text="显示", command=self.toggle_key).pack(side=tk.LEFT, padx=5)
        
        # 2. 提示词
        prompt_box = tk.LabelFrame(left, text="提示词", font=("微软雅黑", 10, "bold"), padx=5, pady=5)
        prompt_box.pack(fill=tk.X, pady=3)
        
        self.prompt = tk.Text(prompt_box, wrap=tk.WORD, height=6, font=("微软雅黑", 11))
        self.prompt.pack(fill=tk.X)
        self.prompt.insert("1.0", "在此输入图像描述...")
        
        # 3. 生成按钮
        gen_btn = tk.Button(left, text="▶ 开始生成", bg="#4CAF50", fg="white",
                           font=("微软雅黑", 14, "bold"), height=2, command=self.generate)
        gen_btn.pack(fill=tk.X, pady=5)
        
        self.progress = ttk.Progressbar(left, mode='determinate', maximum=100)
        self.progress.pack(fill=tk.X, pady=2)
        
        # 4. 参考图片
        img_box = tk.LabelFrame(left, text="参考图片 (拖拽或点击)", font=("微软雅黑", 10, "bold"), padx=5, pady=5)
        img_box.pack(fill=tk.X, pady=3)
        
        img_frame = tk.Frame(img_box)
        img_frame.pack()
        
        for i in range(4):
            zone = DropZone(img_frame, f"图{i+1}", i, self.on_img)
            zone.pack(side=tk.LEFT, padx=2)
            zone.enable_drop()
            self.drop_zones.append(zone)
            
        tk.Button(img_box, text="清除所有", command=self.clear_imgs).pack(fill=tk.X, pady=5)
        
        # 5. 参数设置
        param_box = tk.LabelFrame(left, text="生成参数", font=("微软雅黑", 10, "bold"), padx=5, pady=5)
        param_box.pack(fill=tk.X, pady=3)
        
        # 宽高比
        tk.Label(param_box, text="宽高比:").grid(row=0, column=0, sticky=tk.W, pady=2)
        self.aspect = tk.StringVar(value="自动")
        ttk.Combobox(param_box, textvariable=self.aspect, 
                    values=["自动", "9:16", "16:9", "1:1", "4:3", "3:4", "2:3", "3:2", "21:9"],
                    width=12, state="readonly").grid(row=0, column=1, sticky=tk.W, padx=5, pady=2)
        
        # 尺寸
        tk.Label(param_box, text="图像尺寸:").grid(row=1, column=0, sticky=tk.W, pady=2)
        self.size = tk.StringVar(value="自动")
        ttk.Combobox(param_box, textvariable=self.size,
                    values=["自动", "1K", "2K", "4K", "8K"],
                    width=12, state="readonly").grid(row=1, column=1, sticky=tk.W, padx=5, pady=2)
        
        # Seed
        tk.Label(param_box, text="随机种子:").grid(row=2, column=0, sticky=tk.W, pady=2)
        self.seed = tk.IntVar(value=0)
        ttk.Spinbox(param_box, from_=0, to=2147483647, textvariable=self.seed, width=12).grid(row=2, column=1, sticky=tk.W, padx=5, pady=2)
        
        # 保存路径
        path_box = tk.LabelFrame(left, text="保存设置", font=("微软雅黑", 10, "bold"), padx=5, pady=5)
        path_box.pack(fill=tk.X, pady=3)
        
        path_row = tk.Frame(path_box)
        path_row.pack(fill=tk.X)
        tk.Label(path_row, text="路径:").pack(side=tk.LEFT)
        self.save_path = tk.StringVar(value=os.path.join(os.getcwd(), "generated_images"))
        tk.Entry(path_row, textvariable=self.save_path).pack(side=tk.LEFT, fill=tk.X, expand=True, padx=5)
        tk.Button(path_row, text="浏览", command=self.choose_path).pack(side=tk.LEFT)
        
        # ===== 右侧：结果 =====
        right = tk.Frame(paned, bg="white")
        paned.add(right, stretch="always")
        
        tk.Label(right, text="生成结果", bg="white", font=("微软雅黑", 12, "bold")).pack(anchor=tk.W, padx=10, pady=5)
        
        # 结果区域带滚动
        result_frame = tk.Frame(right, bg="#f5f5f5")
        result_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        
        self.result_canvas = tk.Canvas(result_frame, bg="#f5f5f5", highlightthickness=0)
        scrollbar = ttk.Scrollbar(result_frame, orient=tk.VERTICAL, command=self.result_canvas.yview)
        self.result_canvas.configure(yscrollcommand=scrollbar.set)
        
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.result_canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        self.result_inner = tk.Frame(self.result_canvas, bg="#f5f5f5")
        self.result_canvas.create_window((0, 0), window=self.result_inner, anchor=tk.NW)
        self.result_inner.bind("<Configure>", lambda e: self.result_canvas.configure(scrollregion=self.result_canvas.bbox("all")))
        
        tk.Button(right, text="保存所有图片", command=self.save_all).pack(fill=tk.X, padx=10, pady=5)
        
        # 日志
        log_box = tk.LabelFrame(right, text="日志", font=("微软雅黑", 9), padx=5, pady=5)
        log_box.pack(fill=tk.X, padx=10, pady=5)
        
        self.log_text = tk.Text(log_box, height=5, state=tk.DISABLED, wrap=tk.WORD)
        self.log_text.pack(fill=tk.BOTH, expand=True)
        
    def on_img(self, idx, path):
        self.log(f"图{idx+1}: {os.path.basename(path) if path else '已清除'}")
        
    def clear_imgs(self):
        for z in self.drop_zones:
            z.clear()
        self.log("已清除所有参考图片")
        
    def toggle_key(self):
        show = self.api_key_entry.cget('show') == '*'
        self.api_key_entry.config(show='' if show else '*')
        
    def choose_path(self):
        path = filedialog.askdirectory()
        if path:
            self.save_path.set(path)
            
    def get_aspect(self):
        v = self.aspect.get()
        return None if v == "自动" else v
        
    def get_size(self):
        v = self.size.get()
        return None if v == "自动" else v
        
    def generate(self):
        key = self.api_key.get().strip()
        if not key:
            messagebox.showerror("错误", "请输入API Key")
            return
            
        prompt = self.prompt.get("1.0", tk.END).strip()
        if not prompt or "描述" in prompt:
            messagebox.showerror("错误", "请输入提示词")
            return
            
        threading.Thread(target=self._gen, args=(key, prompt), daemon=True).start()
        
    def _gen(self, key, prompt):
        try:
            self.root.after(0, lambda: self.progress.config(value=10))
            
            url = f"{self.api_url.get()}?key={key}"
            
            parts = [{"text": prompt}]
            for z in self.drop_zones:
                p = z.get_path()
                if p:
                    with open(p, "rb") as f:
                        parts.append({"inline_data": {"mime_type": "image/jpeg", 
                                                      "data": base64.b64encode(f.read()).decode()}})
                                                      
            self.root.after(0, lambda: self.progress.config(value=30))
            
            img_cfg = {}
            a = self.get_aspect()
            s = self.get_size()
            if a: img_cfg["aspectRatio"] = a
            if s: img_cfg["imageSize"] = s
            
            payload = {
                "contents": [{"role": "user", "parts": parts}],
                "generationConfig": {"responseModalities": ["TEXT", "IMAGE"], "imageConfig": img_cfg}
            }
            
            if self.seed.get() > 0:
                payload["generationConfig"]["seed"] = self.seed.get()
            
            self.root.after(0, lambda: self.progress.config(value=50))
            self.log("正在生成...")
            
            resp = requests.post(url, headers={"Content-Type": "application/json", 
                                               "Authorization": f"Bearer {key}"}, 
                               json=payload, timeout=600)
            self.root.after(0, lambda: self.progress.config(value=70))
            
            if resp.status_code != 200:
                self.log(f"错误: {resp.status_code}")
                return
                
            result = resp.json()
            images = []
            
            for cand in result.get("candidates", []):
                for part in cand.get("content", {}).get("parts", []):
                    if "inline_data" in part or "inlineData" in part:
                        data = part.get("inline_data") or part.get("inlineData")
                        images.append(Image.open(BytesIO(base64.b64decode(data["data"]))))
                        
            self.root.after(0, lambda: self.progress.config(value=100))
            
            if images:
                self.root.after(0, lambda: self.show_images(images))
                self.root.after(0, lambda: self.auto_save(images))
                self.log(f"成功生成 {len(images)} 张图片")
            else:
                self.log("未生成图片")
                
        except Exception as e:
            self.log(f"错误: {str(e)}")
            
    def show_images(self, images):
        for w in self.result_inner.winfo_children():
            w.destroy()
        self.generated_images = images
        
        for i, img in enumerate(images):
            f = tk.Frame(self.result_inner, relief=tk.RIDGE, bd=1)
            f.grid(row=i//2, column=i%2, padx=5, pady=5)
            
            thumb = img.copy()
            thumb.thumbnail((300, 300))
            photo = ImageTk.PhotoImage(thumb)
            
            if not hasattr(self, '_photos'):
                self._photos = []
            self._photos.append(photo)
            
            lbl = tk.Label(f, image=photo)
            lbl.pack(padx=5, pady=5)
            tk.Label(f, text=f"{img.size[0]}x{img.size[1]}").pack()
            
            lbl.bind("<Button-1>", lambda e, img=img: self.view_full(img))
            
    def view_full(self, img):
        top = tk.Toplevel(self.root)
        top.title("预览")
        
        disp = img.copy()
        disp.thumbnail((900, 700))
        photo = ImageTk.PhotoImage(disp)
        
        lbl = tk.Label(top, image=photo)
        lbl.image = photo
        lbl.pack(padx=10, pady=10)
        
        tk.Button(top, text="保存", command=lambda: self.save_one(img)).pack(pady=5)
        
    def auto_save(self, images):
        path = self.save_path.get()
        os.makedirs(path, exist_ok=True)
        
        ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        for i, img in enumerate(images):
            img.save(os.path.join(path, f"gemini_{ts}_{i+1}.png"))
        self.log(f"已自动保存到: {path}")
        
    def save_one(self, img):
        f = filedialog.asksaveasfilename(defaultextension=".png")
        if f:
            img.save(f)
            
    def save_all(self):
        if not self.generated_images:
            return
        d = filedialog.askdirectory()
        if d:
            for i, img in enumerate(self.generated_images):
                img.save(os.path.join(d, f"image_{i+1}.png"))
            self.log(f"已保存到: {d}")
            
    def log(self, msg):
        self.log_text.config(state=tk.NORMAL)
        ts = datetime.datetime.now().strftime("%H:%M:%S")
        self.log_text.insert(tk.END, f"[{ts}] {msg}\n")
        self.log_text.see(tk.END)
        self.log_text.config(state=tk.DISABLED)
        
    def save_config(self):
        try:
            cfg = {
                "api_url": self.api_url.get(),
                "api_key": self.api_key.get(),
                "aspect_ratio": self.aspect.get(),
                "image_size": self.size.get(),
                "save_path": self.save_path.get()
            }
            with open("gemini_config.json", "w", encoding="utf-8") as f:
                json.dump(cfg, f, indent=2, ensure_ascii=False)
            self.log("配置已保存")
        except Exception as e:
            self.log(f"保存失败: {e}")
            
    def load_config(self):
        try:
            if os.path.exists("gemini_config.json"):
                with open("gemini_config.json", "r", encoding="utf-8") as f:
                    cfg = json.load(f)
                self.api_url.set(cfg.get("api_url", self.default_api))
                self.api_key.set(cfg.get("api_key", ""))
                self.aspect.set(cfg.get("aspect_ratio", "自动"))
                self.size.set(cfg.get("image_size", "自动"))
                self.save_path.set(cfg.get("save_path", os.path.join(os.getcwd(), "generated_images")))
                self.log("配置已加载")
        except Exception as e:
            self.log(f"加载失败: {e}")


def main():
    global USE_TKDND, TkinterDnD, DND_FILES
    
    try:
        from tkinterdnd2 import TkinterDnD, DND_FILES
        USE_TKDND = True
        root = TkinterDnD.Tk()
    except ImportError:
        USE_TKDND = False
        root = tk.Tk()
        print("拖拽功能未启用")
    
    app = Gemini3ProGUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()
