#done
FROM ubuntu:16.04

RUN apt-get update -y && \
    apt-get install -y python-pip

# We copy just the requirements.txt
COPY ./requirements.txt /application/requirements.txt

WORKDIR /application

RUN pip install -r requirements.txt

COPY . /application

ENTRYPOINT [ "python" ]
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0"]
CMD [ "hello_world.py" ]




