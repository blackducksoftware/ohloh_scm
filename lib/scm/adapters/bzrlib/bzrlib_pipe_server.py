from bzrlib.branch import Branch
from bzrlib.revisionspec import RevisionSpec
import sys
import time 
import traceback

class BzrPipeServer:
  def __init__(self, repository_url):
    self.branch = Branch.open(repository_url)
    self.branch.lock_read()

  def get_file_content(self, filename, revision):
    rev_spec = RevisionSpec.from_string(revision)
    tree = rev_spec.as_tree(self.branch)
    file_id = tree.path2id(filename)
    if file_id == None:
      return None
    content = tree.get_file_text(file_id)
    return content

  def get_parent_tokens(self, revision):
    rev_spec = RevisionSpec.from_string(revision)
    tree = rev_spec.as_tree(self.branch)
    parents = tree.get_parent_ids()
    return parents

  def cleanup(self):
    self.branch.unlock()

class Command:
  def __init__(self, line):
    self.args = line.rstrip().split('|')

  def get_action(self):
    return self.args[0]

  def get_arg(self, num):
    return self.args[num]

def send_status(code, data_len):
  sys.stderr.write('%s%09d' % (code, data_len))
  sys.stderr.flush()

def send_success(data_len=0):
  send_status('T', data_len)

def send_failure(data_len=0):
  send_status('F', data_len)

def send_error(data_len=0):
  send_status('E', data_len)

def send_data(result):
  sys.stdout.write(result)
  sys.stdout.flush()

def exit_delayed(status, delay=1):
  time.sleep(delay)
  sys.exit(status)

def command_loop():
  while True:
    cmd = Command(sys.stdin.readline())
    if cmd.get_action() == 'REPO_OPEN':
      commander = BzrPipeServer(cmd.get_arg(1))
      send_success()
    elif cmd.get_action() == 'CAT_FILE':
      content = commander.get_file_content(cmd.get_arg(2), cmd.get_arg(1))
      if content == None:
        send_failure()
      else:
        send_success(len(content))
        send_data(content)
    elif cmd.get_action() == 'PARENT_TOKENS':
      tokens = commander.get_parent_tokens(cmd.get_arg(1))
      tokens = '|'.join(tokens)
      send_success(len(tokens))
      send_data(tokens)
    elif cmd.get_action() == 'QUIT':
      commander.cleanup()
      send_success()
      exit_delayed(status=0)
    else:
      error = "Invalid Command - %s" % cmd.get_action()
      send_error(len(error))
      send_data(error)
      exit_delayed(status=1)

if __name__ == "__main__":
  try:
    command_loop()
  except:
    exc_trace = traceback.format_exc()
    send_error(len(exc_trace))
    send_data(exc_trace)
    exit_delayed(status=1)
