import boto3

session = boto3.Session(region_name='us-east-1')
client = session.client(service_name='ec2')
all_regions = client.describe_regions()

region_list = ['us-east-1', 'us-east-2']
list_of_regions = []
for each_reg in all_regions['Regions']:
    list_of_regions.append(each_reg['RegionName'])
print(list_of_regions)

for each_reg in list_of_regions:
    session = boto3.Session(region_name=each_reg)
    resource = session.resource(service_name='ec2')
    if each_reg in region_list:
        print("List of services: ", each_reg)
        for each_in_vpc in resource.vpcs.all():
            print(each_in_vpc.id)
        for each_in_subnet in resource.subnets.all():
            print(each_in_subnet.id)
        for each_in_IGW in resource.internet_gateways.all():
            print(each_in_IGW.id)
        for each_in_sg in resource.security_groups.all():
            print(each_in_sg.id)
