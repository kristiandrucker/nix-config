{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.envoyProxy;

  # Type for a virtual host
  virtualHostOpts = {
    name,
    config,
    ...
  }: {
    options = {
      port = mkOption {
        type = types.int;
        description = "The port number where the service is running locally";
        example = 8080;
      };

      enableOidcAuth = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable OpenID Connect authentication for this host";
      };

      clientId = mkOption {
        type = types.str;
        default = "";
        description = "The OAuth client ID";
      };

      clientSecret = mkOption {
        type = types.str;
        default = "";
        description = "The OAuth client secret";
      };

      forceSSL = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to force SSL by redirecting HTTP requests to HTTPS";
      };

      useACMEHost = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Name of the ACME host configuration to use for SSL certificates";
        example = "example.com";
      };

      enableACME = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable ACME (Let's Encrypt) for this virtual host";
      };

      additionalHttpFilters = mkOption {
        type = types.listOf types.attrs;
        default = [];
        description = "Additional HTTP filters to add to the virtual host";
      };

      customRoutes = mkOption {
        type = types.listOf types.attrs;
        default = [];
        description = "Custom routes to add to the virtual host";
      };

      sslCertificate = mkOption {
        type = types.str;
        # This will be overridden if useACMEHost is set
        default = "/var/lib/acme/${name}/fullchain.pem";
        description = "Path to the SSL certificate";
      };

      sslKey = mkOption {
        type = types.str;
        # This will be overridden if useACMEHost is set
        default = "/var/lib/acme/${name}/key.pem";
        description = "Path to the SSL key";
      };

      extraConfig = mkOption {
        type = types.attrs;
        default = {};
        description = "Extra configuration to be merged with the virtual host config";
      };
    };

    config = mkMerge [
      # Set certificate paths if useACMEHost is set
      (mkIf (config.useACMEHost != null) {
        sslCertificate = "/var/lib/acme/${config.useACMEHost}/fullchain.pem";
        sslKey = "/var/lib/acme/${config.useACMEHost}/key.pem";
      })
    ];
  };

  # Create a virtual host configuration
  mkVirtualHost = name: vhost: let
    # Check if SSL should be enabled
    sslEnabled = vhost.forceSSL || vhost.useACMEHost != null;

    # Create a standard HTTP connection manager
    mkHttpConnectionManager = prefix: routes: filters: {
      name = "envoy.filters.network.http_connection_manager";
      typed_config = {
        "@type" = "type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager";
        stat_prefix = prefix;
        codec_type = "AUTO";
        route_config = {
          name = "${name}_route";
          virtual_hosts = [
            {
              name = name;
              domains = [name];
              routes = routes;
            }
          ];
        };
        http_filters = filters;
      };
    };

    # Standard route to backend service
    standardRoutes =
      if vhost.customRoutes != []
      then vhost.customRoutes
      else [
        {
          match = {prefix = "/";};
          route = {
            cluster = "${name}_service";
            host_rewrite_literal = name;
          };
        }
      ];

    # HTTP to HTTPS redirect routes
    redirectRoutes = [
      {
        match = {prefix = "/";};
        redirect = {
          https_redirect = true;
          port_redirect = 443;
        };
      }
    ];

    # OAuth filters if enabled
    oauthFilters =
      if vhost.enableOidcAuth
      then [
        {
          name = "envoy.filters.http.oauth2";
          typed_config = {
            "@type" = "type.googleapis.com/envoy.extensions.filters.http.oauth2.v3.OAuth2";
            config = {
              token_endpoint = {
                cluster = "oauth";
                uri = "${cfg.oidcProvider}/token";
                timeout = "3s";
              };
              authorization_endpoint = "${cfg.oidcProvider}/authorize";
              redirect_uri = "%REQ(x-forwarded-proto)%://%REQ(:authority)%/callback";
              redirect_path_matcher = {
                path = {exact = "/callback";};
              };
              signout_path = {
                path = {exact = "/signout";};
              };
              credentials = {
                client_id = vhost.clientId;
                token_secret = {
                  name = "token_${builtins.replaceStrings ["."] ["_"] name}";
                  sds_config = {
                    path = "/etc/envoy/token-secret-${builtins.replaceStrings ["."] ["_"] name}.yaml";
                  };
                };
                hmac_secret = {
                  name = "hmac_${builtins.replaceStrings ["."] ["_"] name}";
                  sds_config = {
                    path = "/etc/envoy/hmac-${builtins.replaceStrings ["."] ["_"] name}.yaml";
                  };
                };
              };
              auth_type = "PKCE";
              auth_scopes = ["openid" "email" "profile"];
            };
          };
        }
      ]
      else [];

    # Standard router filter
    routerFilter = [
      {
        name = "envoy.filters.http.router";
        typed_config = {
          "@type" = "type.googleapis.com/envoy.extensions.filters.http.router.v3.Router";
        };
      }
    ];

    # Full HTTP filters
    httpFilters = oauthFilters ++ vhost.additionalHttpFilters ++ routerFilter;
  in {
    listeners =
      (
        if sslEnabled
        then [
          # HTTPS Listener when SSL is enabled
          {
            name = "${name}_listener_https";
            address = {
              socket_address = {
                address = "0.0.0.0";
                port_value = 443;
              };
            };
            filter_chains = [
              {
                filters = [
                  (
                    mkHttpConnectionManager
                    (builtins.replaceStrings ["."] ["_"] name)
                    standardRoutes
                    httpFilters
                  )
                ];
                transport_socket = {
                  name = "envoy.transport_sockets.tls";
                  typed_config = {
                    "@type" = "type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext";
                    common_tls_context = {
                      tls_certificates = [
                        {
                          certificate_chain = {filename = vhost.sslCertificate;};
                          private_key = {filename = vhost.sslKey;};
                        }
                      ];
                    };
                  };
                };
              }
            ];
          }
        ]
        else []
      )
      ++ [
        # HTTP Listener (for both SSL-enabled and non-SSL hosts)
        {
          name = "${name}_listener_http";
          address = {
            socket_address = {
              address = "0.0.0.0";
              port_value = 80;
            };
          };
          filter_chains = [
            {
              filters = [
                (
                  mkHttpConnectionManager
                  "${builtins.replaceStrings ["."] ["_"] name}_http"
                  (
                    if vhost.forceSSL
                    then redirectRoutes
                    else standardRoutes
                  )
                  (
                    if vhost.forceSSL
                    then routerFilter
                    else httpFilters
                  )
                )
              ];
            }
          ];
        }
      ];

    cluster =
      {
        name = "${name}_service";
        connect_timeout = "0.25s";
        type = "STRICT_DNS";
        lb_policy = "ROUND_ROBIN";
        load_assignment = {
          cluster_name = "${name}_service";
          endpoints = [
            {
              lb_endpoints = [
                {
                  endpoint = {
                    address = {
                      socket_address = {
                        address = "127.0.0.1";
                        port_value = vhost.port;
                      };
                    };
                  };
                }
              ];
            }
          ];
        };
      }
      // (vhost.extraConfig.cluster or {});

    secretScript = optionalString vhost.enableOidcAuth ''
      # Create token secret file for ${name}
      cat > /etc/envoy/token-secret-${builtins.replaceStrings ["."] ["_"] name}.yaml << EOF
      resources:
      - "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.Secret
        name: token_${builtins.replaceStrings ["."] ["_"] name}
        generic_secret:
          secret:
            inline_string: "${vhost.clientSecret}"
      EOF

      # Create HMAC secret file for ${name}
      cat > /etc/envoy/hmac-${builtins.replaceStrings ["."] ["_"] name}.yaml << EOF
      resources:
      - "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.Secret
        name: hmac_${builtins.replaceStrings ["."] ["_"] name}
        generic_secret:
          secret:
            inline_string: "$(head -c 32 /dev/urandom | base64)"
      EOF

      chmod 600 /etc/envoy/token-secret-${builtins.replaceStrings ["."] ["_"] name}.yaml
      chmod 600 /etc/envoy/hmac-${builtins.replaceStrings ["."] ["_"] name}.yaml
    '';

    # Define ACME needs for this virtual host
    acme = {
      # For enableACME, use the hostname as the domain
      ${
        if vhost.enableACME
        then name
        else null
      } = mkIf vhost.enableACME {
        enable = true;
        group = "envoy";
      };

      # For useACMEHost, use the specified domain
      ${
        if vhost.useACMEHost != null
        then vhost.useACMEHost
        else null
      } = mkIf (vhost.useACMEHost != null) {
        enable = false; # Don't enable ACME automatically - we're just using the cert
        group = "envoy";
      };
    };
  };

  # Transform the attribute set of virtual hosts into a list of virtual host configurations
  virtualHosts = mapAttrs mkVirtualHost cfg.virtualHosts;

  # Collect all listeners and clusters
  allListeners = concatLists (map (vhost: vhost.listeners) (attrValues virtualHosts));
  allClusters = map (vhost: vhost.cluster) (attrValues virtualHosts);
  allSecretScripts = concatStringsSep "\n" (filter (s: s != "") (map (vhost: vhost.secretScript) (attrValues virtualHosts)));

  # Collect all ACME configurations and remove null entries
  acmeConfigs =
    filterAttrs (name: value: name != null)
    (foldl' (acc: vhost: acc // vhost.acme) {} (attrValues virtualHosts));

  # Add OAuth provider cluster if needed
  oauthCluster =
    if cfg.oidcProvider != ""
    then [
      {
        name = "oauth";
        connect_timeout = "5s";
        type = "STRICT_DNS";
        lb_policy = "ROUND_ROBIN";
        load_assignment = {
          cluster_name = "oauth";
          endpoints = [
            {
              lb_endpoints = [
                {
                  endpoint = {
                    address = {
                      socket_address = {
                        # Extract the hostname from the oidcProvider URL
                        address = builtins.head (builtins.match "https?://([^:/]+).*" cfg.oidcProvider);
                        port_value = 443;
                      };
                    };
                  };
                }
              ];
            }
          ];
        };
        transport_socket = {
          name = "envoy.transport_sockets.tls";
          typed_config = {
            "@type" = "type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext";
          };
        };
      }
    ]
    else [];
in {
  options.services.envoyProxy = {
    enable = mkEnableOption "Envoy proxy with simplified virtual host configuration";

    package = mkOption {
      type = types.package;
      default = pkgs.envoy;
      description = "The Envoy package to use";
    };

    adminPort = mkOption {
      type = types.int;
      default = 9901;
      description = "The port for Envoy's admin interface";
    };

    oidcProvider = mkOption {
      type = types.str;
      default = "";
      description = "The base URL for the OpenID Connect provider";
      example = "https://auth.example.com";
    };

    virtualHosts = mkOption {
      type = types.attrsOf (types.submodule virtualHostOpts);
      default = {};
      description = "Attribute set of virtual hosts";
      example = literalExpression ''
        {
          "app.example.com" = {
            port = 8080;
            enableOidcAuth = true;
            clientId = "my-client-id";
            clientSecret = "my-client-secret";
            forceSSL = true;
            useACMEHost = "example.com";
          };
        }
      '';
    };

    extraConfig = mkOption {
      type = types.attrs;
      default = {};
      description = "Extra configuration to be merged with the Envoy configuration";
    };
  };

  config = mkIf cfg.enable {
    # Enable the Envoy service with our merged configuration
    services.envoy = {
      enable = true;
      package = cfg.package;
      requireValidConfig = true;
      settings =
        {
          admin = {
            #            access_log_path = "/var/log/envoy/admin.log";
            address = {
              socket_address = {
                address = "127.0.0.1";
                port_value = cfg.adminPort;
              };
            };
          };

          static_resources = {
            listeners = allListeners;
            clusters = allClusters ++ oauthCluster;
          };
        }
        // cfg.extraConfig;
    };

    # Configure ACME for each virtual host that needs it
    users.groups.envoy = {};
    users.users.envoy = {
      isSystemUser = true;
      group = "envoy";
      # Add envoy to acme group if it exists
      extraGroups = optional (config.security.acme.defaults.group != null) "acme";
    };

    systemd.services.envoy.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "envoy";
      Group = "envoy";
      PrivateTmp = true;
      ProtectHome = lib.mkForce false;
      RuntimeDirectory = "envoy";
      LogsDirectory = "envoy";
      CacheDirectory = "envoy";
      #        Restart = "yes";
    };

    # Create necessary secret files for OAuth2
    #    system.activationScripts.envoySecrets = mkIf (allSecretScripts != "") {
    #      text = ''
    #        mkdir -p /var/log/envoy
    #        mkdir -p /etc/envoy
    #        ${allSecretScripts}
    #      '';
    #      deps = [];
    #    };

    # Ensure the log directory exists
    #    systemd.tmpfiles.rules = [
    #      "d /var/log/envoy 0755 envoy envoy -"
    #    ];

    # Open ports in the firewall
    networking.firewall = {
      allowedTCPPorts = [80 443 9901];
    };
  };
}
