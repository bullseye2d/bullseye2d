# Create a new application

To start a new `Bullseye2D` application, run the following command:

```bash
bullseye2d create ./my_new_game
```

You will be prompted to enter a location where you want to create the new app. A directory will be created for you and it will also be the project name.

The name should be all lowercase, with underscores to separate words, just_like_this. Use only basic Latin letters and Arabic digits: `a-z0-9_`. 

When the project was successfuly created navigate into the directory and start the webserver:

```bash
cd ../my_new_game
webdev serve
```

Open your browser and go to: `http://localhost:8080`.

<details>
<summary>

**Customizing `webdev serve`:**

</summary>
<content>

```bash
# Automatically refresh browser when the app was rebuild
webdev serve --auto refresh

# Specify a port
webdev serve web:8081

# Specify a hostname to make it accessible on your local network
webdev serve --hostname=0.0.0.0

# Disable live reload
webdev serve --no-live-reload

# Enable debugging features for Dart DevTools
webdev serve --debug
```

Refer to the [**webdev**](https://dart.dev/tools/webdev) documentation for more options: `webdev serve --help`.

  </content>
</details>

# Production Builds

When you're ready to deploy your application, you'll want to create an optimized production build.

```bash
# By default that generates an optimized production build in the `build` folder
webdev build
```

