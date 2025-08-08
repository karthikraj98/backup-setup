from odoo import http
from prometheus_client import CollectorRegistry, Gauge, generate_latest, CONTENT_TYPE_LATEST
import datetime

class OdooMetricsController(http.Controller):

    @http.route('/metrics', auth='none', type='http')
    def metrics(self):
        registry = CollectorRegistry()

        # Example metric: number of active sessions
        active_users_gauge = Gauge('odoo_active_users', 'Number of active Odoo users', registry=registry)
        active_users = http.request.env['res.users'].search_count([('login_date', '!=', False)])
        active_users_gauge.set(active_users)

        # Example metric: sales orders today
        sales_today_gauge = Gauge('odoo_sales_orders_today', 'Number of sales orders created today', registry=registry)
        today = datetime.date.today()
        sales_today = http.request.env['sale.order'].search_count([('create_date', '>=', today)])
        sales_today_gauge.set(sales_today)

        # Output in Prometheus format
        data = generate_latest(registry)
        return http.Response(data, content_type=CONTENT_TYPE_LATEST)
