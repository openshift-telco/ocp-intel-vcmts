#### HTTP Server (optional)

If you want to store the packages in an HTTP server you can use this setup.

The `/var/www/html/` folder is persistent, so the data copied there will remain even if the pod is deleted.

In order to copy the released .tar.gz into the HTTP Server, the following commands can be used:

Create the HTTP server:
~~~
$ oc create -f httpd/httpd.yaml
~~~

Find the pod name:
~~~
$ oc get pods -n vcmts-build -l app=http-server
NAME                           READY   STATUS    RESTARTS   AGE
http-server-6469986b9f-h4t2n   1/1     Running   0          22h
~~~

Copy the tarball onto the pod:
~~~
$ oc cp intel-vcmts-image.tar http-server-6469986b9f-xrrcm:/var/www/html/ -n vcmts-build
~~~