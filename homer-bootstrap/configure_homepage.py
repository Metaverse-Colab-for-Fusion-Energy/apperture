import json
import yaml
import os

ORGANISATION = os.environ['ORGANISATION']
TITLE = os.environ['TITLE']
DOMAIN = os.environ['DOMAIN']
DEFAULT_LOGO = 'assets/default_logo.png'
GROUPED_ICONS = {
    'Apps': 'fa-solid fa-rocket'
}


def gen_service(item):
    """
    Generate a service entry for the config file.

    Args:
        item (dict): The service item.

    Returns:
        dict: The generated service entry.
    """
    service = {}
    try:
        service['url'] = 'http://' + item['subdomain'] + '.' + DOMAIN
    except KeyError:
        print('KeyError: subdomain not found in item')
        return None

    if 'name' in item.keys():
        service['name'] = item['name']
    else:
        service['name'] = item['subdomain']

    if 'icon' in item.keys():
        service['icon'] = item['icon']
    elif 'logo' in item.keys():
        service['logo'] = item['logo']
    else:
        service['logo'] = DEFAULT_LOGO

    # if 'tags' in item.keys():
    #     service['tag'] = item['tags']
    if 'description' in item.keys():
        service['subtitle'] = item['description']

    return service


def generate_config(proxy_conf, template):
    """
    Generate the config file based on the template and proxy configuration.

    Args:
        proxy_conf (dict): The proxy configuration.
        template (dict): The template configuration.

    Returns:
        dict: The generated config file.
    """
    # Create a copy of the template
    config = template.copy()

    # Generaic config changes
    config['title'] = TITLE + ' Dashboard'
    config['subtitle'] = ORGANISATION
    config['footer'] = 'Welcome to the ' + ORGANISATION + ' Dashboard'

    config['services'] = []
    services = [[]]
    groups = ['Misc']

    # Update the config with the proxy configuration
    is_grouped = False
    for item in proxy_conf['proxy_hosts']:
        if 'group' in item.keys():
            is_grouped = True
            if item['group'] not in groups:
                groups.append(item['group'])
                services.append([])
            service = gen_service(item)
            services[groups.index(item['group'])].append(service)
        else:
            service = gen_service(item)
            services[0].append(service)

    # Add the services to the config
    if is_grouped:
        if len(services[0]) == 0:
            services.pop(0)
            groups.pop(0)
        for i, group in enumerate(groups):
            if group in GROUPED_ICONS.keys():
                config['services'].append({'name': group, 'icon': GROUPED_ICONS[group], 'items': services[i]})
            else:
                config['services'].append({'name': group, 'logo': DEFAULT_LOGO, 'items': services[i]})
    else:
        config['services']['items'] = services[0]

    # Update the organisation name
    config['organisation'] = ORGANISATION

    return config


def main():
    # Load the config file
    with open('/proxy-bootstrap/config.json', 'r') as file:
        # Load the JSON file
        proxy_conf = json.load(file)

    # Load the template file
    with open('/app/template.yml', 'r') as file:
        # Load the YAML file
        template = yaml.safe_load(file)

    # Generate the config
    config = generate_config(proxy_conf, template)

    # Write the config to a file
    with open('/configs/config.yml', 'w') as f:
        yaml.dump(config, f, default_flow_style=False)

if __name__ == '__main__':
    main()
