
use ModPerl::Registry () ;

use lib qw(/var/www/html/pl /repositorio/servicios/web/webber/proc  /repositorio/servicios/web/webber/webs/wb4/ /repositorio/servicios/web/webber/webs/rediris2/  ) ;

use Webber::FilterRaw  ;
use Webber::FilterHTML ;
Webber::FilterRaw::read_webber_conf("/var/www/html/pl/conf.xml") ;
Webber::FilterHTML::read_webber_conf("/var/www/html/pl/conf.xml") ;

1;
