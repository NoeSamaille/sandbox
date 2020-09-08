IMPORTANT: Review the IBM Cloud Pak for Automation license information here: 

https://github.com/icp4a/cert-kubernetes/blob/20.0.2/LICENSE

Press any key to continue

Do you accept the IBM Cloud Pak for Automation license (Yes/No, default: No): y
Installing the Cloud Pak for Automation Operator...

Is this a new install or an existing install?
1) New
2) Existing
Enter a valid option [1 to 2]: 1

Select the cloud platform to deploy: 
1) Openshift Container Platform (OCP) - Private Cloud
2) Other ( Certified Kubernetes Cloud Platform / CNCF)
Enter a valid option [1 to 2]: 1

What type of deployment is being performed?
1) Demo
2) Enterprise
Enter a valid option [1 to 2]: 1

Do you plan to install Business Automation Workflow and/or Automation Workstream Services?
Enter a valid option [Yes, No]: n

Select the Cloud Pak for Automation capability to install: 
1) FileNet Content Manager (Selected)
2) Automation Content Analyzer (Selected)
3) Operational Decision Manager 
4) Automation Decision Services 
5) Business Automation Application 
6) Automation Digital Worker 

Info: Business Automation Navigator will be automatically installed in the environment as it is part of the Cloud Pak for Automation foundation platform. 

Tips:  After you make your first selection you will be able to make additional selections since you can combine multiple selections. 


Tips:Press [ENTER] when you are done

Pattern "FileNet Content Manager": Select optional components: 
1) Content Search Services (Selected)
2) Content Management Interoperability Services 
3) User Management Service (Selected)
4) Business Automation Insights 

Tips: Press [ENTER] when you are done


Follow the instructions on how to get your Entitlement Registry key: 
https://github.com/icp4a/cert-kubernetes/blob/20.0.2/platform/ocp/install.md

Do you have a Cloud Pak for Automation Entitlement Registry key (Yes/No, default: No): y

Enter your Entitlement Registry key: eyJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJJQk0gTWFya2V0cGxhY2UiLCJpYXQiOjE1Nzg1OTQ1MzEsImp0aSI6IjM5NzM1Yjc4YjNhNDRhMDFiMWQzZmE5M2FmYjg3YjFhIn0.gSlULBb_YTzDH2RdkzyBuE5qVCite2KMBER-nDQjfyE


Verifying the Entitlement Registry key...
Login Succeeded!
Entitlement Registry key is valid.

In order for the deployment to create routes for the Cloud Pak services,
You can get the host name by running the following command: 
oc get route console -n openshift-console -o yaml|grep routerCanonicalHostname
Input the host name: apps.ocp15.iicparis.fr.ibm.com

To provision the persistent volumes and volume claims, enter the dynamic storage classname: managed-nfs-storage

*******************************************************
                    Summary of input                   
*******************************************************
1. Cloud Pak capability to deploy: 
   * FileNet Content Manager
   * Automation Content Analyzer
2. Optional components to deploy: 
   * Content Search Services
   * User Management Service
3. Entitlement Registry key: eyJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJJQk0gTWFya2V0cGxhY2UiLCJpYXQiOjE1Nzg1OTQ1MzEsImp0aSI6IjM5NzM1Yjc4YjNhNDRhMDFiMWQzZmE5M2FmYjg3YjFhIn0.gSlULBb_YTzDH2RdkzyBuE5qVCite2KMBER-nDQjfyE
4. Docker registry service name or URL: 
5. Docker registry user name: 
6. Docker registry password:
7. OCP Infrastructure Node: apps.ocp15.iicparis.fr.ibm.com
8. Dynamic storage classname: managed-nfs-storage
*******************************************************

Verify that the information above is correct.
To proceed with the deployment, enter "Yes".
To make changes, enter "No" (default: No): y  

Installing the Cloud Pak for Automation operator...

Creating docker-registry secret for Entitlement Registry key...
secret/admin.registrykey created
Done

Applying the persistent volumes for the Cloud Pak operator by using the storage classname: managed-nfs-storage...

persistentvolumeclaim/operator-shared-pvc created
Done

Waiting for the persistent volumes to be ready...
Done

Installing the Cloud Pak for Automation operator...
deployment.apps/ibm-cp4a-operator created
Done

Waiting for the Cloud Pak operator to be ready. This might take a few minutes... 
Waiting for deployment "ibm-cp4a-operator" rollout to finish: 0 of 1 updated replicas are available...
deployment "ibm-cp4a-operator" successfully rolled out
deployment "ibm-cp4a-operator" successfully rolled out
Done

Copying the JDBC driver for the operator...
Done

Installing the selected Cloud Pak capability...
icp4acluster.icp4a.ibm.com/icp4adeploy created
Done

The custom resource file used is: "/root/cp4a/scripts/generated-cr/ibm_cp4a_cr_final.yaml"

To monitor the deployment status, follow the Operator logs.
For details, refer to the troubleshooting section in Knowledge Center here: 
https://www.ibm.com/support/knowledgecenter/SSYHZ8_20.0.x/com.ibm.dba.install/op_topics/tsk_trbleshoot_operators.html




