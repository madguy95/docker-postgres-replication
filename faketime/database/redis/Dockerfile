FROM redis:5.0.10-alpine
COPY --from=trajano/alpine-libfaketime  /faketime.so /lib/faketime.so
ENV LD_PRELOAD=/lib/faketime.so \
  DONT_FAKE_MONOTONIC=1