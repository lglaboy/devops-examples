FROM docker.elastic.co/elasticsearch/elasticsearch:7.12.1
# COPY elasticsearch.yml config/elasticsearch.yml
# USER elasticsearch
# RUN elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v7.12.1/elasticsearch-analysis-ik-7.12.1.zip \
#     && elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-pinyin/releases/download/v7.12.1/elasticsearch-analysis-pinyin-7.12.1.zip \
# 官方地址太慢了,手动下载安装
RUN elasticsearch-plugin install --batch http://192.168.1.51/packages/elasticsearch/plugin/elasticsearch-analysis-ik-7.12.1.zip \
    && elasticsearch-plugin install --batch http://192.168.1.51/packages/elasticsearch/plugin/elasticsearch-analysis-pinyin-7.12.1.zip \
    && echo -e 'cluster.name: "cluster"\nnode.master: true\nnode.data: true\nxpack.security.enabled: false\nnetwork.host: 0.0.0.0\ndiscovery.zen.minimum_master_nodes: 1\ndiscovery.type: single-node' > config/elasticsearch.yml
    # && echo 'cluster.name: "cluster"' > config/elasticsearch.yml \
    # && echo 'node.master: true' >> config/elasticsearch.yml \
    # && echo 'node.data: true' >> config/elasticsearch.yml \
    # && echo 'xpack.security.enabled: false' >> config/elasticsearch.yml \
    # && echo 'network.host: 0.0.0.0' >> config/elasticsearch.yml \
    # && echo 'discovery.zen.minimum_master_nodes: 1' >> config/elasticsearch.yml