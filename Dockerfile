FROM seanly/toolset:openjdk-8-2 AS base

FROM base AS datax

USER root
SHELL ["/bin/bash", "-c"]

WORKDIR /code

RUN <<EOF
curl -sLfO https://datax-opensource.oss-cn-hangzhou.aliyuncs.com/202308/datax.tar.gz
tar -xzf datax.tar.gz
EOF

FROM base AS datax-web
USER root
SHELL ["/bin/bash", "-c"]

COPY ./ /code
WORKDIR /code

RUN <<-EOF
set -eux

cp -r /maven-wrapper/* ./
cp -r /maven-wrapper/.mvn ./.mvn
./mvnw -B -e -U clean install -Dmaven.test.skip=true
mkdir -p ./build/datax-web
tar -xzf ./build/datax-web-2.1.2.tar.gz --strip-components=1 -C build/datax-web

EOF

FROM base AS package

WORKDIR /app

COPY --from=datax /code/datax /app/datax
COPY --from=datax-web /code/build/datax-web /app/

RUN <<EOF
bash ./bin/install.sh -f
rm -rf packages
EOF

FROM base
WORKDIR /app
COPY --from=package /app /app
ENV DATAX_HOME=/app/datax

RUN sed -i 's/^nohup //; s/&$//' /app/modules/datax-executor/bin/datax-executor.sh

ENTRYPOINT [ "bash", "./bin/start-all.sh" ]
