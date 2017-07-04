# http4k-bootstrap

Create a full deployment pipeline (Github -> TravisCI -> Heroku) of a [working http4k application](https://github.com/http4k/http4k-heroku-travis-example-app) using a single command:

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

## Prerequisites

* A [GitHub](https://github.com) account.
* A [Heroku](https://www.heroku.com) account.
* The following commands available in your terminal:
  * `jq`
  * `openssl`
* The following environment variables set:
  * `GITHUB_USERNAME` set to the user who'll own your application's git repository.
  * `GITHUB_PERSONAL_ACCESS_TOKEN` for the [GitHub Personal Access Token](https://github.com/settings/tokens) to be used by the script to set up your repository and TravisCI (the owner must be the same user defined above).
  * `HEROKU_API_KEY` for the [Heroku API Key](https://dashboard.heroku.com/account#api-key) to be used by the script to create your app.
