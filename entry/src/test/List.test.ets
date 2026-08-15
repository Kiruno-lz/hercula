import textDateParserTest from './TextDateParser.test';
import importValidatorTest from './ImportValidator.test';
import jsonTransferTest from './JsonTransfer.test';
import responsiveLayoutTest from './ResponsiveLayout.test';

export default function testsuite() {
  textDateParserTest();
  importValidatorTest();
  jsonTransferTest();
  responsiveLayoutTest();
}
