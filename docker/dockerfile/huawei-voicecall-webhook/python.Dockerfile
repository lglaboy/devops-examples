# 基于python开发服务封装
FROM python:3.11.0

ENV TZ=Asia/Shanghai

WORKDIR /voice/
COPY requirements.txt config/config.yml app.py /voice/

RUN pip install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple -r requirements.txt

EXPOSE 8080

ENTRYPOINT ["python","app.py"]
