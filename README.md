# Update Draft Release

Add your latest commit message to your GitHub repository's draft release.

## Setup

Create `~/.netrc` file with your GitHub login/password:

```
machine api.github.com
  login your_login_id
  password your_password_or_token
```

## Usage

```
$ ./bin.rb your/repo
```
