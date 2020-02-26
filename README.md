# make-webhooks

> Just try it: `make web`. ;)

You are now exposing this projects `Makefile` to the web!

```sh
$ curl http://localhost/hello-world
{"status":0}
```

Change environment variables. All vars are uppercased by default.
Dont forget HTTP URL encoding!

```sh
curl http://localhost/hello-world\?GREET\=Anthony
curl "http://localhost/hello-world?GREET=Anthony"
curl "http://localhost/hello-world?greet=Anthony"
```

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
$ curl -H 'Authorization: Bearer mySecret' http://localhost/hello-world ; echo ''
Unauthorized
$ curl -H 'Authorization: Bearer myNewSecret' http://localhost/hello-world ; echo ''
{"status":0}
```
