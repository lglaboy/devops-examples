# claude code 安装脚本分析

提供安装命令

```bash
# linux
curl -s https://vibe.aiok.me/setup-claudecode.sh | bash -s -- --url https://claudexai.com/claudecode --key sk-ant-oat01-Q8W1c69uIJstMsBDrzZwhIsF2PUYBvQR

# windows
& { $url='https://claudexai.com/claudecode'; $key='sk-ant-oat01-Q8W1c69uIJstMsBDrzZwhIsF2PUYBvQR'; iwr -useb https://vibe.aiok.me/setup-claudecode.ps1 | iex }
```

# 文件

1.setup-claudecode.sh linux下安装脚本

2.decrypt_data.sh     linux下安装脚本内解密数据()

```bash
# eval "$(_d "$_data")" "$@"
# 不使用eval，即可输出解密内容，可以看到具体执行的脚本内容
_d "$_data"
```

3.setup-claudecode.ps1 windows下安装脚本