FROM public.ecr.aws/lambda/provided:alami.2023.03.21.19

RUN yum install -y gcc g++ make libatomic readline-devel ncurses-devel openssl-devel zlib-devel libcurl-devel tar gzip

RUN curl https://julialang-s3.julialang.org/bin/linux/x64/1.8/julia-1.8.5-linux-x86_64.tar.gz -o julia.tar.gz \
  && tar -xf julia.tar.gz \
  && rm julia.tar.gz \
  && mv julia-* /opt/julia

ENV PATH=/opt/julia/bin:$PATH

WORKDIR /var/task
ENV JULIA_DEPOT_PATH /var/task/.julia

RUN julia -e "using Pkg; Pkg.add(\"JSON\");"
COPY . .

ENV JULIA_DEPOT_PATH /tmp/.julia:/var/task/.julia

WORKDIR /var/runtime
COPY bootstrap .
RUN chmod +x bootstrap

WORKDIR /opt/extensions

CMD ["JuliaLambdaFunc.lambda_handler"]
