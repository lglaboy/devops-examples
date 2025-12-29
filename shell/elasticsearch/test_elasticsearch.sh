#!/bin/bash

# Elasticsearch 服务器地址
# 测试环境
ES_HOST="http://192.168.1.22:9200"
# 生产环境
#ES_HOST="http://10.43.10.100:9200"
ES_INDEX="doc_hos_info"
USERNAME="elastic"
PASSWORD="elasticpassword"

# 循环插入 1000 条数据
for i in $(seq 0 999); do
  # 定义 JSON 数据
  JSON_DATA=$(cat <<EOF
{
    "id": "$i",
    "yardCode": "99999",
    "yardName": "1",
    "introduction": "介绍",
    "docCode": "1001",
    "docName": "医生1",
    "deptCode": "001",
    "deptName": "神经内科",
    "docTitle": "fsafsadf0",
    "special": "特别重要的",
    "hisDocCode": "搜索2"
}
EOF
)

  # 使用 curl 插入数据
  RESPONSE=$(curl -s -X POST -u "$USERNAME:$PASSWORD" \
    "$ES_HOST/$ES_INDEX/_doc" \
    -H "Content-Type: application/json" \
    -d "$JSON_DATA")

  # 打印结果
  echo "Index $i: $(echo $RESPONSE | jq -r '.result')"
done
