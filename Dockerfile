FROM python:3.9 as python-base

ENV POETRY_VERSION=1.5.1
ENV POETRY_HOME=/opt/poetry
ENV POETRY_VENV=/opt/poetry-venv
ENV POETRY_CACHE_DIR=/opt/.cache

FROM python-base as poetry-base

RUN apt-get update && apt-get install patch

RUN python3 -m venv $POETRY_VENV \
	&& $POETRY_VENV/bin/pip install -U pip setuptools \
	&& $POETRY_VENV/bin/pip install poetry==${POETRY_VERSION}

# Create a new stage from the base python image
FROM python-base as python-app

# Copy Poetry to app image
COPY --from=poetry-base ${POETRY_VENV} ${POETRY_VENV}

ENV PATH="${PATH}:${POETRY_VENV}/bin"

WORKDIR /netdevops

COPY custom_template_file.py custom_gns3fy.py patch_nornir_jinja2.patch patch_gns3fy.patch poetry.lock pyproject.toml ./

RUN poetry config virtualenvs.path /netdevops/virtualenvs && poetry config virtualenvs.in-project true && poetry install

RUN patch -fs $(poetry env info --path)/lib/python3.9/site-packages/nornir_jinja2/plugins/tasks/template_file.py patch_nornir_jinja2.patch

RUN patch -fs $(poetry env info --path)/lib/python3.9/site-packages/gns3fy/gns3fy.py patch_gns3fy.patch