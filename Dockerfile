FROM debian

## Fetch r-base-core and create r-environment and myscripts directories
RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get update -y \
 && apt-get install -y apt-utils gnupg2 \
 && echo "deb http://cloud.r-project.org/bin/linux/debian bookworm-cran40/" >> /etc/apt/sources.list \
 && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 95C0FAF38DB3CCAD0C080A7BDC78B2DDEABC47B7 \
 && apt-get update -y \
 && apt-get dist-upgrade -y \
 && apt-get install -y --no-install-suggests --no-install-recommends r-base-core \
 && apt-get update -y \
 && mkdir /usr/local/src/myscripts

## Copy executable to myscripts directory
COPY dummy.R /usr/local/src/myscripts/dummy.R

## Install BiocManager to install MSstats
RUN Rscript -e "install.packages('BiocManager', lib = '/usr/local/lib/R/site-library')" \
&& Rscript -e "BiocManager::install(version = '3.20', lib = '/usr/local/lib/R/site-library')" \
&& Rscript -e "BiocManager::install('MSstats', version = '3.20', lib = '/usr/local/lib/R/site-library')" \ 
&& Rscript -e "BiocManager::install('MSstatsTMT', version = '3.20', lib = '/usr/local/lib/R/site-library')" 

## change back to directory where script is located
WORKDIR /usr/local/src/myscripts 
## Run the script upon container start
CMD ["Rscript", "dummy.R"]
