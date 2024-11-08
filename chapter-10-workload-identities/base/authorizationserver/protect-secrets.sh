#!/bin/bash

##############################################################################################
# A script to protect secure environment variables before deploying the authorization server
# In a real setup this type of logic is typically run by CI/CD component with access to secrets
###############################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Get the platform
#
case "$(uname -s)" in

  Darwin)
    PLATFORM="MACOS"
    export OPENSSL_CONF='/System/Library/OpenSSL/openssl.cnf'
 	;;

  MINGW64*)
    PLATFORM="WINDOWS"
    export OPENSSL_CONF='C:/Program Files/Git/usr/ssl/openssl.cnf';
    export MSYS_NO_PATHCONV=1;
	;;

  Linux)
    PLATFORM="LINUX"
    export OPENSSL_CONF='/usr/lib/ssl/openssl.cnf';
	;;
esac

#
# Windows specific fixes
#
LINE_SEPARATOR='\n';
if [ "$PLATFORM" == 'WINDOWS' ]; then
  
  # Fix problems with trailing newline characters in Docker scripts downloaded from Git
  sed -i 's/\r$//' encrypt-util.sh

  # Use the Windows line separator
  LINE_SEPARATOR='\r\n';
fi

#
# Hash the admin password
#
ADMIN_PASSWORD_RAW='Password1'
ADMIN_PASSWORD=$(openssl passwd -5 $ADMIN_PASSWORD_RAW)

#
# Plaintext database details
#
DB_NAME='idsvrdb'
DB_USER='idsvruser'
DB_PASSWORD_RAW='Password1'
DB_CONNECTION_RAW="jdbc:postgresql://postgres-svc/$DB_NAME"

#
# The example deployment generates a symmetric key, used to encrypt authorization server cookies
#
SYMMETRIC_KEY_RAW=$(openssl rand 32 | xxd -p -c 64)

#
# The example deployment generates a token signing public key
#
cd resources
openssl ecparam -name prime256v1 -genkey -noout -out signing.key
openssl req -new -key signing.key -out signing.csr -subj "/CN=curity.signing"
openssl x509 -req -in signing.csr -signkey signing.key -out signing.crt -days 365
openssl pkcs12 -export -inkey signing.key -in signing.crt -name curity.signing -out signing.p12 -passout pass:Password1
rm signing.csr 2>/dev/null
cd ..

#
# Run a temporary instance of the Curity Identity Server docker container that will perform encryption related tasks
#
docker rm -f curity 1>/dev/null 2>&1
docker run -d -p 6749:6749 -e PASSWORD=Password1 --user root --name curity curity.azurecr.io/curity/idsvr:latest 1>/dev/null
if [ $? -ne 0 ]; then
  echo '*** Problem encountered running the utility docker image'
  exit 1
fi
trap 'docker rm -f curity 1>/dev/null 2>&1' EXIT

#
# Wait for its admin endpoint to become available
#
echo 'Waiting for the temporary idsvr docker container, which will perform encryption tasks ...'
while [ "$(curl -k -s -o /dev/null -w ''%{http_code}'' "https://localhost:6749/admin/login/login.html")" != '200' ]; do
  sleep 2
done

#
# Copy the encryption script to the container
#
echo 'Protecting secure environment variables ...'
docker cp ./encrypt-util.sh curity:/tmp/
docker exec -i curity bash -c 'chmod +x /tmp/encrypt-util.sh'

#
# Use the encryption script to get the encrypted DB password
#
DB_PASSWORD=$(docker exec -i curity bash -c "TYPE=plaintext PLAINTEXT='$DB_PASSWORD_RAW' ENCRYPTIONKEY='$CONFIG_ENCRYPTION_KEY' /tmp/encrypt-util.sh")
if [ $? -ne 0 ]; then
  echo "*** Problem encountered encrypting the DB password: $DB_PASSWORD"
  exit 1
fi

#
# Use the encryption script to get the encrypted DB connection
#
DB_CONNECTION=$(docker exec -i curity bash -c "TYPE=plaintext PLAINTEXT='$DB_CONNECTION_RAW' ENCRYPTIONKEY='$CONFIG_ENCRYPTION_KEY' /tmp/encrypt-util.sh")
if [ $? -ne 0 ]; then
  echo "*** Problem encountered encrypting the DB connection: $DB_CONNECTION"
  exit 1
fi

#
# Use the encryption script to get the encrypted symmetric key
#
SYMMETRIC_KEY=$(docker exec -i curity bash -c "TYPE=plaintext PLAINTEXT='$SYMMETRIC_KEY_RAW' ENCRYPTIONKEY='$CONFIG_ENCRYPTION_KEY' /tmp/encrypt-util.sh")
if [ $? -ne 0 ]; then
  echo "*** Problem encountered encrypting the symmetric key: $SYMMETRIC_KEY"
  exit 1
fi

#
# Convert the token signing key from a P12 to the Curity protected format
#
SIGNING_KEY_BASE64="$(openssl base64 -in resources/signing.p12 | tr -d $LINE_SEPARATOR)"
SIGNING_KEY_RAW=$(docker exec -i curity bash -c "convertks --in-password Password1 --in-alias curity.signing --in-entry-password Password1 --in-keystore '$SIGNING_KEY_BASE64'")
if [ $? -ne 0 ]; then
  echo "*** Problem encountered converting the token signing key: $SIGNING_KEY_RAW"
  exit 1
fi

#
# Use the encryption script to get the encrypted token signing key
#
SIGNING_KEY=$(docker exec -i curity bash -c "TYPE=base64keystore PLAINTEXT='$SIGNING_KEY_RAW' ENCRYPTIONKEY='$CONFIG_ENCRYPTION_KEY' /tmp/encrypt-util.sh")
if [ $? -ne 0 ]; then
  echo "*** Problem encountered encrypting the token signing key: $SIGNING_KEY"
  exit 1
fi

#
# Create the namespace
#
kubectl delete namespace authorizationserver 2>/dev/null
kubectl create namespace authorizationserver
if [ $? -ne 0 ]; then
  echo '*** Problem encountered creating the authorizationserver namespace'
  exit 1
fi

#
# Create a secret containing protected environment variables
#
kubectl -n authorizationserver delete secret idsvr-secureconfig-properties 2>/dev/null
kubectl -n authorizationserver create secret generic idsvr-secureconfig-properties \
  --from-literal="ADMIN_PASSWORD=$ADMIN_PASSWORD" \
  --from-literal="DB_USER=$DB_USER" \
  --from-literal="DB_PASSWORD=$DB_PASSWORD" \
  --from-literal="DB_CONNECTION=$DB_CONNECTION" \
  --from-literal="SYMMETRIC_KEY=$SYMMETRIC_KEY" \
  --from-literal="SIGNING_KEY=$SIGNING_KEY" \
  --from-literal="LICENSE_KEY=$LICENSE_KEY"
if [ $? -ne 0 ]; then
  echo "Problem encountered creating the Kubernetes secret containing secure environment variables"
  exit 1
fi
