ARG IMAGE=containers.intersystems.com/intersystems/iris-community:2025.1
FROM $IMAGE

USER root
RUN apt update \
    && apt install -y git
WORKDIR /opt/src
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/src
USER ${ISC_PACKAGE_MGRUSER}

# ビルド中に実行したいスクリプトがあるファイルをコンテナにコピーしています
COPY iris.script .
COPY src .
COPY data .
COPY requirements.txt .
COPY fish_text_vectors.jsonl .

# IRISを開始し、IRISにログインし、iris.scriptに記載のコマンドを実行しています
RUN iris start IRIS \
    && pip install -r requirements.txt --break-system-packages \
    && iris session IRIS < iris.script \
    && iris stop IRIS quietly 