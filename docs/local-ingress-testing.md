## Simulate a Real Domain Locally using /etc/hosts

We will now simulate a real domain by accessing our local microservice via postman at:

```http://accounts.fake.com/actuator/health```

1. Firstly run this command:

```kubectl get ingress accounts -n default```

Take note of the ADDRESS value — that's your ALB's DNS.

2. Edit ```/etc/hosts``` on your machine

```sudo nano /etc/hosts```

3. Test in Postman.