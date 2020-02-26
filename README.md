# Makefile Hook

Webhooks for your project made simple. Most projects have a Makefile, why not
just expose an API to run them?

```
echo 'test:\n\texit 0' > Makefile
docker run -d --rm \
  -v $(PWD):/webhook \
  -p 3000:3000 \
  --name make-webhook \
  expelledboy/make-webhook
curl http://localhost:3000/test

# Cleanup
docker stop make-webhook
```


