{application, ftp,
 [{description, "FTP client"},
  {vsn, "1.0.4"},
  {registered, []},
  {mod, { ftp_app, []}},
  {applications,
   [kernel,
    stdlib
   ]},
  {env,[]},
  {modules, [
             ftp,
             ftp_app,
             ftp_progress,
             ftp_response,
             ftp_sup
            ]},
  {runtime_dependencies, ["erts-7.0","stdlib-3.5","kernel-6.0"]}
 ]}.
