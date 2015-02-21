import socket


def resolv(hostname):
    try:
        return socket.gethostbyname(hostname)
    except socket.gaierror as e:
        raise Exception('Cloud not resolv "%s": %s' % (hostname, e))


class FilterModule(object):
    filter_map = {
        'resolv': resolv,
    }

    def filters(self):
        return {'resolv': resolv}
