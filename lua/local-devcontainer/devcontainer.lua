local termitary = require 'termitary-mod'

local M = {}

local cfg = require('local-devcontainer.settings').config

function M._devcontainer_up()
  local args = cfg.devcontainer.args or {}
  local cmd = {
    cfg.devcontainer.path,
    'up',
  }

  for _, v in pairs(args) do
    table.insert(cmd, v)
  end
  termitary.type(cmd)
end

function M._setup_ssh()
  local cmds = {
    [[
      function _setup_ssh() {
        local container_id
        local container_hostname
        local public_key
        public_key=$1
        local ip_address
        container_id=$(devcontainer up --workspace-folder=. --skip-post-create --skip-non-blocking-commands --skip-post-attach | tail -n1 | jq -r .containerId)
        container_hostname=$(docker inspect $container_id --format='{{.Config.Hostname}}')
        ip_address=$(docker inspect $container_hostname --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
        devcontainer exec --workspace-folder=. mkdir -p /home/vscode/.ssh
        docker cp $public_key $container_id:/home/vscode/.ssh/authorized_keys
        devcontainer exec --workspace-folder=. bash -c 'chmod 644 /home/vscode/.ssh/authorized_keys'
        devcontainer exec --workspace-folder=. bash -c 'chmod 700 /home/vscode/.ssh'
        echo $ip_address
      }
    ]],
    vim.fn.join({
      'ip_address=',
      '`',
      '_setup_ssh ',
      cfg.ssh.public_key_path,
      '`',
    }, ''),
    [[
      function _forward_ssh_port() {
        local ip_address
        local port
        local secret_key_path
        local user
        ip_address=$1
        port=$2
        secret_key_path=$3
        user=$4
        term_cmd=$5
        command=$(lsof -i:$port | grep socat | tail -n1 | awk '{ printf $1 }')
        pid=$(lsof -i:$port | tail -n1 | awk '{ printf $2 }')
        if test -n "$command"; then
          echo -n "Port $port is already used. Do you kill the process? If no, port forwarding abort. [y/n]: "
          read kp
          echo "$kp"
          if test "$kp" = "y"; then
            kill -9 $pid
          else
            echo "port forwarding abort. container ip address is $ip_address:$port"
            # return 1
          fi
        fi
        nohup socat tcp-listen:$port,fork tcp-connect:$ip_address:$port >/dev/null 2>&1 &
        sleep 0.5

        if test -n "$term_cmd"; then
          $term_cmd ssh -t -i $secret_key_path \
            -o NoHostAuthenticationForLocalhost=yes \
            -o UserKnownHostsFile=/dev/null \
            -o GlobalKnownHostsFile=/dev/null \
            -p $port \
            $user@$ip_address
        fi
      }
    ]],
    vim.fn.join({ '_forward_ssh_port', '$ip_address', cfg.ssh.port, cfg.ssh.secret_key_path, cfg.ssh.user, '"' .. cfg.cmd .. '"' }, ' '),
  }

  for _, cmd in ipairs(cmds) do
    termitary.type { cmd }
  end
  if cfg.cmd == '' then
    require('osc52').copy(vim.fn.join({
      'ssh -t -i',
      cfg.ssh.secret_key_path,
      '-o NoHostAuthenticationForLocalhost=yes',
      '-o UserKnownHostsFile=/dev/null',
      '-o GlobalKnownHostsFile=/dev/null',
      '-p',
      cfg.ssh.port,
      cfg.ssh.user .. '@' .. cfg.ssh.host,
    }, ' '))
  end
end

function M.devcontainer_up()
  M._devcontainer_up()
  M._setup_ssh()
end

return M
