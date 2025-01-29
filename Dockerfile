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
 && mkdir /usr/local/src/myscripts \
 && mkdir /usr/local/src/log_files \
 && mkdir /usr/local/src/pdp_input \
 && mkdir /usr/local/src/msstats_output

 ## Install BiocManager to install MSstats
RUN Rscript -e "install.packages('BiocManager', lib = '/usr/local/lib/R/site-library')" \
&& Rscript -e "BiocManager::install(version = '3.20', lib = '/usr/local/lib/R/site-library')" \
&& Rscript -e "BiocManager::install('MSstats', version = '3.20', lib = '/usr/local/lib/R/site-library')" \ 
&& Rscript -e "BiocManager::install('MSstatsTMT', version = '3.20', lib = '/usr/local/lib/R/site-library')" 

## Need to allow user to define a local host PATH. This cannot happen in image build, have to execute .sh to define MY_PATH
COPY entrypoint.sh /usr/local/src/myscripts/entrypoint.sh
## Copy executable to myscripts directory
COPY test.R /usr/local/src/myscripts/test.R

## Run one time set up during build so file has correct permissions
RUN chmod +x /usr/local/src/myscripts/entrypoint.sh

## change back to directory where script is located
WORKDIR /usr/local/src/myscripts 

##set entrypoint to run the script when the container starts
ENTRYPOINT ["sh", "/usr/local/src/myscripts/entrypoint.sh"]
## All user set MY_PATH contents should now be in /usr/local/src/pdp_input
