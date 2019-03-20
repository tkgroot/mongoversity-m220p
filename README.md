# M220P Course of Mongo University with Docker

## Installation

### Prior Container Build

Before building the container with docker there are some things that need to be
done to be able to build this container successfully. This setup was developed
on a UNIX based system. There are slight differences when using it on a non-UNIX
system, ex. the volume mount, further below, cannot be set with `${PWD}`.


#### requirements.txt

Change the versions of the following packages in the `requirements.txt`. The
will resolve the issue `ipython 7.3.0 has requirement
prompt-toolkit<2.1.0,>=2.0.0, but you'll have prompt-toolkit 1.0.15 which is
incompatible.`

```txt
jupyter-client==5.2.4     # previously 5.2.3
jupyter-console==6.0.0    # previously 5.2.0
```

#### config.py

Create the `config.py` file and copy the content below into the new file. Place
the file inside your mflix-python directory.

```python
import os
import configparser


_config = configparser.ConfigParser()
_config.read(os.path.abspath(os.path.join(".ini")))


class Config(object):
    HOST = "0.0.0.0"
    DEBUG = True


class ProductionConfig(Config):
    MFLIX_DB_URI = _config['PROD']['MFLIX_DB_URI']
    SECRET_KEY = _config['PROD']['SECRET_KEY']


class TestConfig(Config):
    HOST = "127.0.0.1"
    TESTING = True
    MFLIX_DB_URI = _config['TEST']['MFLIX_DB_URI']
    SECRET_KEY = _config['TEST']['SECRET_KEY']
```

#### Other file updates

Change the files `run.py`, `factory.py` and `tests/conftest.py` to use the
configurations from `config.py` like is shown below.

```diff
 from mflix.factory import create_app

-import os
-import configparser
-
-
-config = configparser.ConfigParser()
-config.read(os.path.abspath(os.path.join(".ini")))

 if __name__ == "__main__":
-    app = create_app()
-    app.config['DEBUG'] = True
-    app.config['MFLIX_DB_URI'] = config['PROD']['MFLIX_DB_URI']
-    app.config['SECRET_KEY'] = config['PROD']['SECRET_KEY']
-
-    app.run()
+    app = create_app(config="config.ProductionConfig")
+    app.run(host=app.config['HOST'])
```

> The term `ProductionConfig` is used in the context of the M220P course.

```diff
-def create_app():
+def create_app(config):

     APP_DIR = os.path.abspath(os.path.dirname(__file__))
     STATIC_FOLDER = os.path.join(APP_DIR, 'build/static')
@@ -31,6 +31,8 @@
     app = Flask(__name__, static_folder=STATIC_FOLDER,
                 template_folder=TEMPLATE_FOLDER,
                 )
+
+    app.config.from_object(config)
```

```diff
 import pytest
 from mflix.factory import create_app

-import os
-import configparser
-
-config = configparser.ConfigParser()
-config.read(os.path.abspath(os.path.join(".ini")))
-

 @pytest.fixture
 def app():
-    app = create_app()
-    app.config['SECRET_KEY'] = config['TEST']['SECRET_KEY']
-    app.config['MFLIX_DB_URI'] = config['TEST']['MFLIX_DB_URI']
+    app = create_app(config="config.TestConfig")
     return app
```

The folder structure of your project should now look somewhat like this:

```
| mflix-python/
|   .ini
|   config.py
|   run.py
|   tests/
|    conftests.py
|    ...
| .dockerignore
| .gitignore
| docker-entrypoint.sh
| Dockerfile
```

## Docker Container

The container installs the `mongodb-org-shell` and `mongodb-org-tools` of
version `4.0.6`. So you can use the mongo shell to connect to your atlas cluster
and run the mongorestore command via the docker container.

The build size of the container is estimated to be approx. `450MiB`.

> Keep in mind that this docker container is not intended to ever see the lights
  of a production environment. Its purpose is to serve as a development
  environment for the M220P course of the mongo university.

#### Build process

If you want to include the `.ini` file during the build process,
you have to comment out the line in `.dockerignore`, where the `.ini` file is
referenced.

Build the container by running the docker build command:

```bash
$> docker image build -t m220p:latest .
```

### Starting the application

```bash
$> docker container run -itd --rm \
  -p 5000:5000 \                                        # port-mapping to host - flask port
  -p 8888:8888 \                                        # port-mapping to host - jupyter notebook port
  -v ${PWD}/mflix-python/.ini:/app/.ini \               # copy the ini into the docker container
  -v ${PWD}/mflix-python/mflix/db.py:/app/mflix/db.py \ # changes to your db.py will force flask to reload
  --name m220p \                                        # how you want to call the container, can be whatever
  m220p:latest                                          # the name of the image you just build
```

Command in one-line without comments:

```bash
docker container run -itd --rm -p 5000:5000 -p 8888:8888 -v ${PWD}/mflix-python/.ini:/app/.ini -v ${PWD}/mflix-python/mflix/db.py:/app/mflix/db.py --name m220p m220p:latest
```

Browse to [localhost:5000](http://localhost:5000) to access the mflix
application.

### Jupyter Notebook

Use [localhost:8888](http://localhost:8888) to get the jupyter
notebook web access. Here you are prompted to enter a token, if used for the
first time. The token can be found when executing the following on the shell:

```bash
$> docker container logs m220p
[I 15:26:23.850 NotebookApp] Writing notebook server cookie secret to /root/.local/share/jupyter/runtime/notebook_cookie_secret
[I 15:26:24.293 NotebookApp] Serving notebooks from local directory: /app
[I 15:26:24.294 NotebookApp] The Jupyter Notebook is running at:
[I 15:26:24.294 NotebookApp] http://(6e2a4193425c or 127.0.0.1):8888/?token=[token-id]
```

Simply copy and paste the `[token-id]` from the command line into the input
field, where the token is required.

### Running Pytests

The tests cannot use a local mongodb server, since the docker container doesn't
have a mongodb server installed. Have that in mind when you edit your `.ini`
test section.
To run the pytest suite simply execute the pytest command inside the container:

```bash
docker container exec -it m220p pytest -m [testname]
```

### Connect to Atlas Cluster

```bash
# connect to your Atlas Cluster
docker container exec -it m220p mongo "mongodb+srv://[user]:[password]@[cluster]"

# import data into Atlas
docker container exec -it m220p mongorestore --drop --gzip --uri \
"mongodb+srv://[username]:[password]@[cluster]" data
```

## Final Note

This is not intended to ever run in production.