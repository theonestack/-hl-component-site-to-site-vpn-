# site-to-site VPN CfHighlander component

## Build status
![cftest workflow](https://github.com/theonestack/hl-component-site-to-site-vpn/actions/workflows/rspec.yaml/badge.svg)
## Parameters

| Name | Use | Default | Global | Type | Allowed Values |
| ---- | --- | ------- | ------ | ---- | -------------- |
| EnvironmentName | Tagging | dev | true | string
| EnvironmentType | Tagging | development | true | string | ['development','production']
| VPCId | Security Groups | None | false | AWS::EC2::VPC::Id
| CGWIpAddress | Customer Gateway IP Address | None | false | string
| DestinationCidrBlock | Destination CIDR block | None | false | string
| RouteTableIds | Comma delimited list of route tables to update | None | false | string

## Outputs/Exports

| Name | Value | Exported |
| ---- | ----- | -------- |


## Included Components
[lib-ec2](https://github.com/theonestack/hl-component-lib-ec2)
[lib-iam](https://github.com/theonestack/hl-component-lib-iam)

## Example Configuration
### Highlander
```
  Component name: 'vpn', template: 'site-to-site-vpn' do
    parameter name: 'VPCId', value: 'vpc.VPCId'
    parameter name: 'CGWIpAddress', value: Ref('CGWIpAddress')
    parameter name: 'DestinationCidrBlock', value: Ref('DestinationCidrBlock')
    parameter name: 'RouteTableIds', value: 'vpc.RouteTableIds'
    parameter name: 'CGWbgpasn', value: Ref('CGWbgpasn')
  end

```
### Site-to-Site VPN Configuration
```
customer_gateway_bgpasn: 
  Ref: CGWbgpasn

static_routes_only: true

tunnel_options:
  - PreSharedKey: 
      Ref: PreSharedKey
```

## Cfhighlander Setup

install cfhighlander [gem](https://github.com/theonestack/cfhighlander)

```bash
gem install cfhighlander
```

or via docker

```bash
docker pull theonestack/cfhighlander
```
## Testing Components

Running the tests

```bash
cfhighlander cftest site-to-site-vpn
```