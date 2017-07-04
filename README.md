# http4k-bootstrap

Create a full deployment pipeline (Github -> TravisCI -> Heroku) using a single command:

This should generate an output like the following:

```bash
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
