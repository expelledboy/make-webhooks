# make-webhooks

> Just try it!

```sh
make web # ;)
```

You are now exposing this projects `Makefile` to the web!

```sh
$ curl http://localhost/hello-world
{"status":0}
```

You can set environment variables, all vars are uppercased by default.
Dont forget HTTP URL encoding!

```sh
curl http://localhost/hello-world\?GREET\=Anthony
curl "http://localhost/hello-world?GREET=Anthony"
curl "http://localhost/hello-world?greet=Anthony"
```


## Getting Started

> Shut up and get me running!

Mount local directory into docker swarm:

```sh
ssh root@server
docker swarm init
wget https://raw.githubusercontent.com/expelledboy/make-webhooks/master/Makefile
make HOSTNAME=webhooks.example.com start-webhooks
```

> OR

Build a docker image with your custom Makefile.

```dock
FROM expelledboy/make-webhooks:latest
RUN apk add --no-cache jq # Makefile deps
COPY Makefile /webhook/Makefile
```

```sh
docker build -t my-webhooks .
docker run -it --rm -p 3000:3000 my-webhooks
```

## Guide

You can use the webhooks return status as an exit code in another script.

```sh
#!/bin/bash

if [ "$1" -eq "run-webhook" ]; then
  exit $(curl -s http://localhost/crash | jq '.status')
fi
```

```sh
$ ./script.sh; echo $?
0
$ ./script.sh run-webhook; echo $?
2
```

Example usage in the command line.

```sh
$ `exit $(curl -s http://localhost/crash | jq '.status')`; echo $?
2
```

But best yet, in a make target!

```make
run-webhook:
	@curl -fs http://localhost/crash
```

```sh
$ make run-webhook
make: *** [Makefile:86: run-webhook] Error 22
```

### Security

We match the Bearer token in the Authorization header, either with environment
variable `SECRET`, or the contents of the file located at `/webhooks/SECRET`.

```sh
$ echo mySecret > SECRET
$ curl http://localhost/hello-world
Unauthorized
$ curl -H 'Authorization: Bearer mySecret' http://localhost/hello-world
{"status":0}
```

Can even do key rotations!

```sh
$ echo -n myNewSecret > SECRET
$ curl -H 'Authorization: Bearer mySecret' http://localhost/hello-world
Unauthorized
$ curl -H 'Authorization: Bearer myNewSecret' http://localhost/hello-world
{"status":0}
```
