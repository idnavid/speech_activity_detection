#include <string>
#include "util/common-utils.h"
#include "base/kaldi-common.h"


int main(int argc, char *argv[]) {
	typedef kaldi::int32 int32;
	using namespace kaldi;

	const char *usage = "substract loglikelihoods from model1 and model2 for a given test file. \n";

    kaldi::ParseOptions po(usage);
	po.Read(argc, argv);

	if (po.NumArgs() != 3) {
        po.PrintUsage();
        exit(1);
    }

    std::string modelLLks1 = po.GetArg(1),
                modelLLks2 = po.GetArg(2),
                outScores  = po.GetArg(3);

    SequentialBaseFloatVectorReader llk_reader1(modelLLks1);
    SequentialBaseFloatVectorReader llk_reader2(modelLLks2);
    BaseFloatVectorWriter score_writer(outScores);

    for (; !llk_reader1.Done(); llk_reader1.Next()) {
        std::string key1 = llk_reader1.Key();
        std::string key2 = llk_reader2.Key();

        if (key1 != key2) {
            KALDI_ERR << modelLLks1 << " and " << modelLLks2 << "must be in the same order";
        }
        Vector<BaseFloat> llks1 = llk_reader1.Value();
        Vector<BaseFloat> llks2 = llk_reader2.Value();
        Vector<BaseFloat> scores = llks1;
        scores.AddVec(-1,llks2);
        llk_reader2.Next();
        score_writer.Write(key1, scores);
    }

}