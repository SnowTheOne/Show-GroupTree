Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module ActiveDirectory

function Show-GroupTree {
    param (
        [string]$StartGroup
    )

    $visitedGroups = @{}
    $userPaths = @{}

    # Fenster erstellen
    $form = New-Object Windows.Forms.Form
    $form.Text = "AD-Gruppenstruktur: $StartGroup"
    $form.Size = New-Object Drawing.Size(800, 600)

    # TreeView erstellen
    $treeView = New-Object Windows.Forms.TreeView
    $treeView.Dock = 'Fill'
    $form.Controls.Add($treeView)

    function Add-GroupNode {
        param (
            [System.Windows.Forms.TreeNode]$parentNode,
            [string]$groupName,
            [string]$path
        )

        if ($path -match "(^|>)$groupName(>|$)") {
            $node = $parentNode.Nodes.Add("$groupName (Zyklus!)")
            $node.ForeColor = 'Red'
            return
        }

        $node = $parentNode.Nodes.Add($groupName)

        try {
            $members = Get-ADGroupMember -Identity $groupName -ErrorAction Stop
        } catch {
            $node.Nodes.Add("(Fehler beim Abrufen)")
            return
        }

        foreach ($member in $members) {
            if ($member.objectClass -eq 'group') {
                Add-GroupNode -parentNode $node -groupName $member.Name -path "$path>$groupName"
            } else {
                $userKey = "$($member.SamAccountName)"
                if ($userPaths.ContainsKey($userKey)) {
                    $child = $node.Nodes.Add("$($member.SamAccountName) (Duplikat)")
                    $child.ForeColor = 'Orange'
                } else {
                    $userPaths[$userKey] = $true
                    $node.Nodes.Add($member.SamAccountName)
                }
            }
        }
    }

    $rootNode = New-Object Windows.Forms.TreeNode
    $rootNode.Text = $StartGroup
    $treeView.Nodes.Add($rootNode)

    Add-GroupNode -parentNode $rootNode -groupName $StartGroup -path ""

    $rootNode.Expand()
    [void]$form.ShowDialog()
}

# Beispiel-Aufruf:
Show-GroupTree -StartGroup "GruppeA"
