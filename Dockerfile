FROM python:3.7-alpine

COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

ENTRYPOINT ["python", "main.py"]

COPY . .
