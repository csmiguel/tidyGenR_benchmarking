# template
git init
# create repo online
git remote add origin https://<TOKEN>@github.com/csmiguel/<REPO-NAME>.git
#first commit
git add .
git commit -m "first commit"
# confirm you do not want to override repo before pushing with this command:
git push -f -u origin main
