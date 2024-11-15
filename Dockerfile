# Copyright Istio Authors
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

FROM python:3.12.1-slim

WORKDIR /

COPY requirements.txt ./
RUN pip3 install -vvv --require-hashes --no-cache-dir -r requirements.txt

COPY test-requirements.txt ./
RUN pip3 install --no-cache-dir --require-hashes -r test-requirements.txt

COPY productpage.py /opt/microservices/
COPY tests/unit/* /opt/microservices/
COPY templates /opt/microservices/templates
COPY static /opt/microservices/static
COPY requirements.txt /opt/microservices/

ARG flood_factor
ENV FLOOD_FACTOR=${flood_factor:-0}

EXPOSE 9080
WORKDIR /opt/microservices
RUN python -m unittest discover

# RUN pip install opentelemetry-sdk opentelemetry-instrumentation opentelemetry-exporter-otlp

RUN pip install opentelemetry-distro opentelemetry-exporter-otlp
RUN opentelemetry-bootstrap -a install

# RUN pip install opentelemetry-instrumentation opentelemetry-exporter-otlp
ENV OTEL_EXPORTER_OTLP_ENDPOINT="http://tempo-simplest-distributor.door-tracing.svc.cluster.local:4318"
ENV OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf"
ENV OTEL_SERVICE_NAME="kubecon-products"
ENV OTEL_LOG_LEVEL="debug"
ENV OTEL_PROPAGATORS="tracecontext"

ENV FLASK_APP=productpage.py
# CMD ["opentelemetry-instrument", "gunicorn", "-b", "[::]:9080", "productpage:app", "-w", "8", "--keep-alive", "2", "-k", "gevent"]
# CMD ["opentelemetry-instrument", "python", "productpage.py"]
CMD ["opentelemetry-instrument", "python", "-m", "flask", "run", "--host=0.0.0.0", "--port=9080"]


USER 1000
