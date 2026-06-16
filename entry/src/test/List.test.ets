import localUnitTest from './LocalUnit.test';
import orpheusUrlRouterTest from './OrpheusUrlRouter.test';

export default function testsuite() {
  localUnitTest();
  orpheusUrlRouterTest();
}