FROM mambaorg/micromamba:0.21.2
COPY --chown=mambauser:mambauser  microenv.yaml /tmp/env-raw.yaml
ARG MAMBA_DOCKERFILE_ACTIVATE=1
RUN grep -v "^name:" /tmp/env.yaml | grep -v "^prefix:" > /tmp/env.yaml
RUN micromamba install -y --file env.yaml && \
     micromamba clean --all --yes
