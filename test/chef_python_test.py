import logging
import time

import pytest

"""import testbase.whisper
import testutils.assertion
import testutils.misc
"""

CHECK_INTERVAL_SECS = 120


def get_file_modify_utime(ssh, filepath):
    """SSH to run a python snippet to get the modify time for a file in
    Unix time
    """
    python_snippet = (
        "import os; "
        "stat_result = os.stat('%s'); "
        "print stat_result.st_mtime") % filepath
    cmd = """python  -c "%s" """ % python_snippet
    file_modify_utime = float(ssh.execute_simple(cmd).split('\n')[0])
    logging.info({'file': filepath, 'modify_utime': file_modify_utime})
    return file_modify_utime


def file_modified_recently(ssh, filepath, task_interval_secs):
    file_modify_utime = get_file_modify_utime(ssh, filepath)
    return file_modify_utime > (time.time() - task_interval_secs)


@pytest.mark.long_test
class TestPeriodicTasks(testbase.whisper.StackTestCase):
    """Tests for SEC-1198: integration test for each periodic task to check the
    task is run according to the task_interval. Each test checks the modify
    time of the associated log file and checks until times out according to its
    task interval. It waits to handle newly created log file.

    Pseudo code for each check:
        task_logfile_modify_utime > now_utime - task_interval
    """

    def test_every_node_tasks(self):
        logfile = '/var/log/chef/client.log'
        task_interval_secs = 30 * 60

        sshs = [
            self.lm_node.ssh,
            self.cm_node.ssh,
            self.sh_node.ssh
        ]
        for idx_node in self.idx_nodes:
            sshs.append(idx_node.ssh)

        for ssh in sshs:
            task_scheduled_correctly = testutils.assertion.PollAssertion(
                file_modified_recently,
                args=(ssh, logfile, task_interval_secs), expected_value=True,
                timeout_seconds=task_interval_secs,
                sleep_interval=CHECK_INTERVAL_SECS,
                msg="file=%s not modified within seconds=%s" % (
                    logfile, task_interval_secs))
            task_scheduled_correctly.poll()

    def test_cluster_master_tasks(self):

        logfile = '/opt/log/whisper_monitoring/splunk_cluster_peer_check.log'
        task_interval_secs = 5 * 60

        task_scheduled_correctly = testutils.assertion.PollAssertion(
            file_modified_recently,
            args=(self.cm_node.ssh, logfile, task_interval_secs),
            expected_value=True, timeout_seconds=task_interval_secs,
            sleep_interval=CHECK_INTERVAL_SECS,
            msg="file=%s not modified within seconds=%s" % (
                logfile, task_interval_secs))
        task_scheduled_correctly.poll()

    def test_license_master_tasks(self):

        logfile = '/opt/log/whisper_monitoring/splunk_license_monitor.log'
        task_interval_secs = 60 * 60

        task_scheduled_correctly = testutils.assertion.PollAssertion(
            file_modified_recently,
            args=(self.lm_node.ssh, logfile, task_interval_secs),
            expected_value=True, timeout_seconds=task_interval_secs,
            sleep_interval=CHECK_INTERVAL_SECS,
            msg="file=%s not modified within seconds=%s" % (
                logfile, task_interval_secs))
        task_scheduled_correctly.poll()

    def test_indexers_tasks(self):

        logfile = '/opt/log/whisper_monitoring/splunk_index_latency.log'
        task_interval_secs = 5 * 60

        for idx_node in self.idx_nodes:
            task_scheduled_correctly = testutils.assertion.PollAssertion(
                file_modified_recently,
                args=(idx_node.ssh, logfile, task_interval_secs),
                expected_value=True, timeout_seconds=task_interval_secs,
                sleep_interval=CHECK_INTERVAL_SECS,
                msg="file=%s not modified within seconds=%s" % (
                    logfile, task_interval_secs))
            task_scheduled_correctly.poll()

        logfile = '/opt/log/whisper_monitoring/splunk_index_usage.log'
        task_interval_secs = 5 * 60

        for idx_node in self.idx_nodes:
            task_scheduled_correctly = testutils.assertion.PollAssertion(
                file_modified_recently,
                args=(idx_node.ssh, logfile, task_interval_secs),
                expected_value=True, timeout_seconds=task_interval_secs,
                sleep_interval=CHECK_INTERVAL_SECS,
                msg="file=%s not modified within seconds=%s" % (
                    logfile, task_interval_secs))
            task_scheduled_correctly.poll()
