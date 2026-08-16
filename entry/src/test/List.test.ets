import dateUtilsTest from './DateUtils.test';
import textDateParserTest from './TextDateParser.test';
import importValidatorTest from './ImportValidator.test';
import importPipelineTest from './ImportPipeline.test';
import jsonTransferTest from './JsonTransfer.test';
import preferencesStoreTest from './PreferencesStore.test';
import responsiveLayoutTest from './ResponsiveLayout.test';
import menstrualDataTest from './MenstrualData.test';

export default function testsuite() {
  dateUtilsTest();
  textDateParserTest();
  importValidatorTest();
  importPipelineTest();
  jsonTransferTest();
  preferencesStoreTest();
  responsiveLayoutTest();
  menstrualDataTest();
}
