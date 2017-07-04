# http4k-bootstrap

Create a full deployment pipeline (Github -> TravisCI -> Heroku) of a working http4k application using a single command:

```bash
curl -s https://raw.githubusercontent.com/http4k/http4k-bootstrap/master/create-app.sh  \
  -o /tmp/create-app.sh && bash /tmp/create-app.sh
```

This should generate an output like the following:

```bash
Enter your app name: my-awesome-app
Setting up my-awesome-app

Creating Heroku app...
Creating GitHub repository...
Enabling TravisCI...
Preparing application skeleton...
Pushing deployment configuration...

Your application should be now ready:
 * Source code: [...]/my-awesome-app
 * TravisCI: https://travis-ci.org/my-github-user/my-awesome-app
 * Heroku deployment: http://my-awesome-app.herokuapp.com
```
