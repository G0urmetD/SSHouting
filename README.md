# SSHouting [WORK IN PROGRESS]
Automates the setup of ssh &amp; able to update the keys frequently


## Usage
- Installation with ssh-key & user file from distribution server
```bash
./sshouting.sh --install \
  --Username admin@<distribution-server> \
  --ssh-key ~/.ssh/id_rsa \
  --allow-users /etc/ssh/allowed_users.txt
```

- Basic Installation & Update of ssh-key & user file
```bash
  # basic installation
./sshouting.sh --install

# update ssh-key & user file
./sshouting.sh --update-keys \
  --Username admin@verteilerserver \
  --ssh-key ~/.ssh/id_rsa
```
