FROM nvidia/cuda:11.6.0-base-ubuntu20.04


RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENV TZ=Asia/Tokyo

ARG UID
ARG GID
ARG UNAME

ENV UID ${UID}
ENV GID ${GID}
ENV UNAME ${UNAME}

RUN echo ${GID} ${UID} ${UNAME}
RUN  groupadd -g ${GID} ${UNAME}
RUN useradd -u ${UID} -g ${UNAME} -m ${UNAME}

ENV PATH $PATH:/usr/local/bin
ENV PATH $PATH:/home/${UNAME}/.local/bin
WORKDIR ./working

USER root
RUN apt-get update
RUN apt-get install -y software-properties-common tzdata
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get -y install python3.10 python3.10-distutils python3-pip
RUN apt-get -y install curl
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10

USER ${UNAME}
RUN python3.10 -m pip install -U pip wheel setuptools
RUN pip --no-cache-dir install torch==1.11.0+cu113 torchvision==0.12.0+cu113 \
    torchaudio==0.11.0+cu113 -f https://download.pytorch.org/whl/cu113/torch_stable.html

RUN pip install ipywidgets \
    jupyterlab \
    jupyter

#additional module
RUN python3.10 -m pip install iterative-stratification \
&&  python3.10 -m pip install transformers \
&&  python3.10 -m pip install pandas 

RUN python3.10 -m pip install matplotlib

USER root
RUN apt-get update 
RUN apt-get install -y openssh-server
RUN mkdir /var/run/sshd

ARG ROOT_PASSWORD=root
RUN echo root:${ROOT_PASSWORD} | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
RUN sed -i 's/#Port 22/Port 8888/' /etc/ssh/sshd_config
RUN mkdir /root/.ssh
RUN mkdir /root/.ssh/authorized_keys
COPY ./.ssh/id_rsa.pub /root/.ssh/authorized_keys
#RUN /usr/sbin/sshd && tail -f /dev/null &
RUN chmod 600 /root/.ssh/authorized_keys
RUN chmod 700 /root/.ssh
RUN /usr/sbin/sshd && tail -f /dev/null &
RUN ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
RUN mkdir /workspace
WORKDIR /workspace
RUN mkdir ./working
RUN ls -al 
RUN chown ${UNAME}:${UNAME} ./working

#additional path
ENV PATH $PATH:DISPLAY=:0

#additional module
USER root
RUN apt-get -y install python3.10-tk
RUN apt install sqlite3

USER ${UNAME}
#CMD ["/usr/sbin/sshd","-D"]
WORKDIR /workspace/working
EXPOSE 8888
#RUN mkdir /home/tomoki/.jupyter


#additional module

