FROM croservices/cro-http:0.8.4
RUN mkdir /app
COPY . /app
WORKDIR /app
RUN zef install --deps-only . && perl6 -c -Ilib service.p6
ENV HICRO_HOST="0.0.0.0" HICRO_PORT="10000"
EXPOSE 10000
CMD perl6 -Ilib service.p6
