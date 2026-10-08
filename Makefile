
include mkinclude/packer.mk
include mkinclude/govc.mk


VSPHERE_FOLDER ?= build-d2iq-base-templates
RELEASE_FOLDER ?= d2iq-base-templates
NAME_POSTFIX ?= -manual-build-$(shell whoami)

PACKER_CACHE_DIR ?= ./packer_cache
PACKER_ON_ERROR ?= cleanup

manifests/d2iq-base-%$(NAME_POSTFIX).json: packer.initialized vsphere.pkr.hcl $(GOVC)
	$(PACKER) build -force -var vsphere_folder=$(VSPHERE_FOLDER) -var vm_name=$(shell basename -s .json $@) -var vm_name_prefix="" -var vm_name_postfix="" -on-error="$(PACKER_ON_ERROR)"  -var-file=./images/base-$*.pkrvar.hcl -var manifest_output=$@ vsphere.pkr.hcl

.PHONY: manifests/d2iq-base-%$(NAME_POSTFIX).json.clean
manifests/d2iq-base-%$(NAME_POSTFIX).json.clean: manifests/d2iq-base-%$(NAME_POSTFIX).json
	bash -x mkinclude/helper_deletetemplate.sh $(shell jq -r '.builds[0].custom_data.template' $<) "" $(shell jq -r '.builds[0].custom_data.resource_pool' $<)
	mv $< $@

manifests/tests/d2iq-base-%$(NAME_POSTFIX).json: manifests/d2iq-base-%$(NAME_POSTFIX).json clone-test.pkr.hcl
	$(PACKER) build -force -var vsphere_folder=$(VSPHERE_FOLDER) -var vm_name=test-$(shell basename -s .json $<) -var template_manifest=$< -var manifest_output=$@ -on-error="$(PACKER_ON_ERROR)" clone-test.pkr.hcl

manifests/ovf/d2iq-base-%$(NAME_POSTFIX).ovf: manifests/d2iq-base-%$(NAME_POSTFIX).json
	bash mkinclude/helper_markasvm.sh $(VSPHERE_FOLDER)/d2iq-base-$* "" $(shell jq -r '.builds[0].custom_data.resource_pool' $<)
	$(GOVC) export.ovf -dc=$(shell jq -r '.builds[0].custom_data.datacenter' $<) -vm=$(VSPHERE_FOLDER)/$(shell jq -r '.builds[0].custom_data.template_name' $<) $@
	tar -czf $@.tar.gz $@/*

# manifests/ova/d2iq-base-%$(NAME_POSTFIX).ova: manifests/ovf/d2iq-base-%$(NAME_POSTFIX).ovf
# 	tar -cvf $@ $</d2iq-base-$*$(NAME_POSTFIX)/*.ovf $</d2iq-base-$*$(NAME_POSTFIX)/*.vmdk

.PHONY: manifests/tests/d2iq-base-%$(NAME_POSTFIX).json.clean
manifests/tests/d2iq-base-%$(NAME_POSTFIX).json.clean: manifests/tests/d2iq-base-%$(NAME_POSTFIX).json
	$(GOVC) vm.destroy /$(shell jq -r '.builds[0].custom_data.datacenter' $<)/vm/$(VSPHERE_FOLDER)/test-$(shell basename -s .json $<)
	mv $< $@

.PHONY: release/d2iq-base-%$(NAME_POSTFIX)
release/d2iq-base-%$(NAME_POSTFIX): manifests/d2iq-base-%$(NAME_POSTFIX).json
	bash mkinclude/helper_deletetemplate.sh $(RELEASE_FOLDER)/d2iq-base-$* "" $(shell jq -r '.builds[0].custom_data.resource_pool' $<)
	$(GOVC) object.rename /$(shell jq -r '.builds[0].custom_data.datacenter' $<)/vm/$(shell jq -r '.builds[0].custom_data.template_name' $<) d2iq-base-$*
	$(GOVC) object.mv /$(shell jq -r '.builds[0].custom_data.datacenter' $<)/vm/$(VSPHERE_FOLDER)/d2iq-base-$* /$(shell jq -r '.builds[0].custom_data.datacenter' $<)/vm/$(RELEASE_FOLDER)

ubuntu: manifests/d2iq-base-Ubuntu-20.04$(NAME_POSTFIX).json manifests/d2iq-base-Ubuntu-22.04$(NAME_POSTFIX).json manifests/d2iq-base-Ubuntu-24.04$(NAME_POSTFIX).json
ubuntu-20-test: manifests/tests/d2iq-base-Ubuntu-20.04$(NAME_POSTFIX).json.clean
ubuntu-20-test-clean: ubuntu-20-test manifests/d2iq-base-Ubuntu-20.04$(NAME_POSTFIX).json.clean 
ubuntu-22-test: manifests/tests/d2iq-base-Ubuntu-22.04$(NAME_POSTFIX).json.clean
ubuntu-22-test-clean: ubuntu-22-test manifests/d2iq-base-Ubuntu-22.04$(NAME_POSTFIX).json.clean
ubuntu-24-test: manifests/tests/d2iq-base-Ubuntu-24.04$(NAME_POSTFIX).json.clean
ubuntu-24-test-clean: ubuntu-24-test manifests/d2iq-base-Ubuntu-24.04$(NAME_POSTFIX).json.clean
ubuntu-test: ubuntu-20-test-clean ubuntu-22-test-clean ubuntu-24-test-clean
ubuntu-20-release: ubuntu-20-test release/d2iq-base-Ubuntu-20.04$(NAME_POSTFIX)
ubuntu-22-release: ubuntu-22-test release/d2iq-base-Ubuntu-22.04$(NAME_POSTFIX)
ubuntu-24-release: ubuntu-24-test release/d2iq-base-Ubuntu-24.04$(NAME_POSTFIX)
ubuntu-release: ubuntu-20-release ubuntu-22-release ubuntu-24-release
ubuntu-20-ovf: manifests/ovf/d2iq-base-Ubuntu-20.04$(NAME_POSTFIX).ovf
ubuntu-22-ovf: manifests/ovf/d2iq-base-Ubuntu-22.04$(NAME_POSTFIX).ovf
ubuntu-24-ovf: manifests/ovf/d2iq-base-Ubuntu-24.04$(NAME_POSTFIX).ovf
ubuntu-ovf: ubuntu-20-ovf ubuntu-22-ovf ubuntu-24-ovf 

rocky: manifests/d2iq-base-RockyLinux-8.7$(NAME_POSTFIX).json manifests/d2iq-base-RockyLinux-9.1$(NAME_POSTFIX).json manifests/d2iq-base-RockyLinux-9.6$(NAME_POSTFIX).json manifests/d2iq-base-RockyLinux-9.5$(NAME_POSTFIX).json manifests/d2iq-base-RockyLinux-9.7$(NAME_POSTFIX).json manifests/d2iq-base-RockyLinux-9.8$(NAME_POSTFIX).json
rocky-8.7-test: manifests/tests/d2iq-base-RockyLinux-8.7$(NAME_POSTFIX).json.clean
rocky-8.7-test-clean: rocky-8.7-test manifests/d2iq-base-RockyLinux-8.7$(NAME_POSTFIX).json.clean
rocky-9.1-test: manifests/tests/d2iq-base-RockyLinux-9.1$(NAME_POSTFIX).json.clean
rocky-9.1-test-clean: rocky-9.1-test manifests/d2iq-base-RockyLinux-9.1$(NAME_POSTFIX).json.clean
rocky-9.5-test: manifests/tests/d2iq-base-RockyLinux-9.5$(NAME_POSTFIX).json.clean
rocky-9.5-test-clean: rocky-9.5-test manifests/d2iq-base-RockyLinux-9.5$(NAME_POSTFIX).json.clean
rocky-9.6-test: manifests/tests/d2iq-base-RockyLinux-9.6$(NAME_POSTFIX).json.clean
rocky-9.6-test-clean: rocky-9.6-test manifests/d2iq-base-RockyLinux-9.6$(NAME_POSTFIX).json.clean
rocky-9.7-test: manifests/tests/d2iq-base-RockyLinux-9.7$(NAME_POSTFIX).json.clean
rocky-9.8-test: manifests/tests/d2iq-base-RockyLinux-9.8$(NAME_POSTFIX).json.clean
rocky-9.7-test-clean: rocky-9.7-test manifests/d2iq-base-RockyLinux-9.7$(NAME_POSTFIX).json.clean
rocky-9.8-test-clean: rocky-9.8-test manifests/d2iq-base-RockyLinux-9.8$(NAME_POSTFIX).json.clean
rocky-test: rocky-8.7-test-clean rocky-9.1-test-clean rocky-9.6-test-clean rocky-9.7-test-clean rocky-9.8-test-clean #rocky-9.5-test-clean
rocky-8.7-release: rocky-8.7-test release/d2iq-base-RockyLinux-8.7$(NAME_POSTFIX)
rocky-9.1-release: rocky-9.1-test release/d2iq-base-RockyLinux-9.1$(NAME_POSTFIX)
rocky-9.5-release: rocky-9.5-test release/d2iq-base-RockyLinux-9.5$(NAME_POSTFIX)
rocky-9.6-release: rocky-9.6-test release/d2iq-base-RockyLinux-9.6$(NAME_POSTFIX)
rocky-9.7-release: rocky-9.7-test release/d2iq-base-RockyLinux-9.7$(NAME_POSTFIX) 
rocky-9.8-release: rocky-9.8-test release/d2iq-base-RockyLinux-9.8$(NAME_POSTFIX)
rocky-release: rocky-8.7-release rocky-9.1-release rocky-9.6-release rocky-9.7-release rocky-9.8-release #rocky-9.5-release
rocky-8.7-ovf: manifests/ovf/d2iq-base-RockyLinux-8.7$(NAME_POSTFIX).ovf
rocky-9.1-ovf: manifests/ovf/d2iq-base-RockyLinux-9.1$(NAME_POSTFIX).ovf
rocky-9.5-ovf: manifests/ovf/d2iq-base-RockyLinux-9.5$(NAME_POSTFIX).ovf
rocky-9.6-ovf: manifests/ovf/d2iq-base-RockyLinux-9.6$(NAME_POSTFIX).ovf
rocky-9.7-ovf: manifests/ovf/d2iq-base-RockyLinux-9.7$(NAME_POSTFIX).ovf
rocky-9.8-ovf: manifests/ovf/d2iq-base-RockyLinux-9.8$(NAME_POSTFIX).ovf
rocky-ovf: rocky-8.7-ovf rocky-9.1-ovf rocky-9.5-ovf rocky-9.6-ovf rocky-9.7-ovf rocky-9.8-ovf

centos: manifests/d2iq-base-CentOS-7.9$(NAME_POSTFIX).json
centos-7.9-test: manifests/tests/d2iq-base-CentOS-7.9$(NAME_POSTFIX).json.clean
centos-7.9-test-clean: centos-7.9-test manifests/d2iq-base-CentOS-7.9$(NAME_POSTFIX).json.clean
centos-test: centos-7.9-test-clean
centos-7.9-release: centos-7.9-test release/d2iq-base-CentOS-7.9$(NAME_POSTFIX)
centos-release: centos-7.9-release
centos-7.9-ovf: manifests/ovf/d2iq-base-CentOS-7.9$(NAME_POSTFIX).ovf
centos-ovf: centos-7.9-ovf

rhel: manifests/d2iq-base-RHEL-86$(NAME_POSTFIX).json manifests/d2iq-base-RHEL-88$(NAME_POSTFIX).json manifests/d2iq-base-RHEL-810$(NAME_POSTFIX).json manifests/d2iq-base-RHEL-94$(NAME_POSTFIX).json manifests/d2iq-base-RHEL-96$(NAME_POSTFIX).json
rhel-8.4-test: manifests/tests/d2iq-base-RHEL-84$(NAME_POSTFIX).json.clean
rhel-8.4-test-clean: rhel-8.4-test manifests/d2iq-base-RHEL-84$(NAME_POSTFIX).json.clean
rhel-8.6-test: manifests/tests/d2iq-base-RHEL-86$(NAME_POSTFIX).json.clean
rhel-8.6-test-clean: rhel-8.6-test manifests/d2iq-base-RHEL-86$(NAME_POSTFIX).json.clean
rhel-8.8-test: manifests/tests/d2iq-base-RHEL-88$(NAME_POSTFIX).json.clean
rhel-8.8-test-clean: rhel-8.8-test manifests/d2iq-base-RHEL-88$(NAME_POSTFIX).json.clean
rhel-8.10-test: manifests/tests/d2iq-base-RHEL-810$(NAME_POSTFIX).json.clean
rhel-8.10-test-clean: rhel-8.10-test manifests/d2iq-base-RHEL-810$(NAME_POSTFIX).json.clean
rhel-9.4-test: manifests/tests/d2iq-base-RHEL-94$(NAME_POSTFIX).json.clean
rhel-9.4-test-clean: rhel-9.4-test manifests/d2iq-base-RHEL-94$(NAME_POSTFIX).json.clean
rhel-9.6-test: manifests/tests/d2iq-base-RHEL-96$(NAME_POSTFIX).json.clean
rhel-9.6-test-clean: rhel-9.6-test manifests/d2iq-base-RHEL-96$(NAME_POSTFIX).json.clean
rhel-test: rhel-8.4-test-clean rhel-8.6-test-clean rhel-8.8-test-clean rhel-8.10-test-clean rhel-9.4-test-clean rhel-9.6-test-clean
rhel-8.4-release: rhel-8.4-test release/d2iq-base-RHEL-84$(NAME_POSTFIX)
rhel-8.6-release: rhel-8.6-test release/d2iq-base-RHEL-86$(NAME_POSTFIX)
rhel-8.8-release: rhel-8.8-test release/d2iq-base-RHEL-88$(NAME_POSTFIX)
rhel-8.10-release: rhel-8.10-test release/d2iq-base-RHEL-810$(NAME_POSTFIX)
rhel-9.4-release: rhel-9.4-test release/d2iq-base-RHEL-94$(NAME_POSTFIX)
rhel-9.6-release: rhel-9.6-test release/d2iq-base-RHEL-96$(NAME_POSTFIX)
rhel-release: rhel-8.4-release rhel-8.6-release rhel-8.8-release rhel-8.10-release rhel-9.4-release rhel-9.6-release
rhel-8.4-ovf: manifests/ovf/d2iq-base-RHEL-84$(NAME_POSTFIX).ovf
rhel-8.6-ovf: manifests/ovf/d2iq-base-RHEL-86$(NAME_POSTFIX).ovf
rhel-8.8-ovf: manifests/ovf/d2iq-base-RHEL-88$(NAME_POSTFIX).ovf
rhel-8.10-ovf: manifests/ovf/d2iq-base-RHEL-810$(NAME_POSTFIX).ovf
rhel-9.4-ovf: manifests/ovf/d2iq-base-RHEL-94$(NAME_POSTFIX).ovf
rhel-9.6-ovf: manifests/ovf/d2iq-base-RHEL-96$(NAME_POSTFIX).ovf
rhel-ovf: rhel-8.4-ovf rhel-8.6-ovf rhel-8.8-ovf rhel-8.10-ovf rhel-9.4-ovf rhel-9.6-ovf

oraclelinux: manifests/d2iq-base-OracleLinux-810$(NAME_POSTFIX).json manifests/d2iq-base-OracleLinux-94$(NAME_POSTFIX).json
oraclelinux-8.10-test: manifests/tests/d2iq-base-OracleLinux-810$(NAME_POSTFIX).json.clean
oraclelinux-8.10-test-clean: oraclelinux-8.10-test manifests/d2iq-base-OracleLinux-810$(NAME_POSTFIX).json.clean
oraclelinux-9.4-test: manifests/tests/d2iq-base-OracleLinux-94$(NAME_POSTFIX).json.clean
oraclelinux-9.4-test-clean: oraclelinux-9.4-test manifests/d2iq-base-OracleLinux-94$(NAME_POSTFIX).json.clean
oraclelinux-test: oraclelinux-8.10-test-clean oraclelinux-9.4-test-clean
oraclelinux-8.10-release: oraclelinux-8.10-test release/d2iq-base-OracleLinux-810$(NAME_POSTFIX)
oraclelinux-9.4-release: oraclelinux-9.4-test release/d2iq-base-OracleLinux-94$(NAME_POSTFIX)
oraclelinux-release: oraclelinux-8.10-release oraclelinux-9.4-release
oraclelinux-8.10-ovf: manifests/ovf/d2iq-base-OracleLinux-810$(NAME_POSTFIX).ovf
oraclelinux-9.4-ovf: manifests/ovf/d2iq-base-OracleLinux-94$(NAME_POSTFIX).ovf
oraclelinux-ovf: oraclelinux-8.10-ovf oraclelinux-9.4-ovf

flatcar: manifests/d2iq-base-Flatcar-4081.3.10$(NAME_POSTFIX).json
flatcar-4081.3.10-test: manifests/tests/d2iq-base-Flatcar-4081.3.10$(NAME_POSTFIX).json
flatcar-4081.3.10-test-clean: flatcar-4081.3.10-test manifests/d2iq-base-Flatcar-4081.3.10$(NAME_POSTFIX).json.clean
flatcar-test: flatcar-4081.3.10-test-clean
flatcar-4081.3.10-release: flatcar-4081.3.10-test release/d2iq-base-Flatcar-4081.3.10$(NAME_POSTFIX)
flatcar-release: flatcar-4081.3.10-release
flatcar-4081.3.10-ovf: manifests/ovf/d2iq-base-Flatcar-4081.3.10$(NAME_POSTFIX).ovf
flatcar-ovf: flatcar-4081.3.10-ovf


test-all: ubuntu-test rocky-test centos-test rhel-test oraclelinux-test
release: ubuntu-release rocky-release centos-release rhel-release oraclelinux-release

.PHONY: list-os-versions
list-os-versions:
	@grep -E '^.+-test-clean:' Makefile | grep -v '@grep' | sed 's/-test-clean//' | cut -d':' -f1  | sort | uniq
