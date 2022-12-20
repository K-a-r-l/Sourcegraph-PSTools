# Sourcegraph-PSTools

Random tools I've written for me/work.

#### SourceGraph-DeleteCodeHosts.ps1

Used to pull a list of Azure DevOps (git, not TVFS) projects/repositories that your PAT (Personal Access Token) has access to, then add them to Sourcegraph as generic git repositories.

It uses the environmental variables (see line ~190):
* ADOPersonalAccessToken : Your Azure DevOps PAT (from memory this needs the code read scope)
* ADOCodeHostNamePrefix : Used as a prefix for repos added to Sourcegraph. This is so you know all repos starting with "<company> ADO - " were added by this script - which is useful when there are problems and you want to delete them all ;)
* ADOOrgList: A comma delimted list of ADO organizations you want to sync the repos for
* SourceGraphBaseUri : Sourcegraph URL: https://sourcegraph.example.com
* SourceGraphAPIToken : Your Sourcegraph API token

#### SourceGraph-DeleteCodeHosts.ps1

Useful for deleting Sourcegraph repos with a text filter on the name (like when the above script has an issue and adds each repo dozens of times...)
