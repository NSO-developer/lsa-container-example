ARG  type ver
 
FROM cisco-nso-$type:$ver
COPY requirements.txt /requirements.txt
RUN pip install --upgrade pip && \
	pip install -r requirements.txt 

#Yum install
#RUN yum -y install <dependency> && \
#    rm -rf /tmpm/* && \
#    yum remove unzip -y && \
#    yum clean all && \
#    rm -rf /var/cache/yum
 
#Dnf install
#RUN dnf -y update
#RUN dnf install -y <dependency> && \
#    dnf clean all

RUN echo "alias ll='ls -alF'" >> ~/.bashrc

EXPOSE 22 80 443 2024 830 4334 2022
