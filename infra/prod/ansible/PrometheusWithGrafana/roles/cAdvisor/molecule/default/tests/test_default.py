import os
import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ["MOLECULE_INVENTORY_FILE"]
).get_hosts("all")


def test_service(host):
    result = host.ansible("debug", "var=cadvisor_in_docker")
    cadvisor_in_docker = host.file(result["cadvisor_in_docker"])
    if not cadvisor_in_docker:
        assert host.service("cadvisor").is_running
        assert host.service("cadvisor").is_enabled


def test_metrics(host):
    out = host.check_output("curl http://0.0.0.0:9280/metrics")
    assert "cadvisor_version_info{" in out
